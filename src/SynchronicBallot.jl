module SynchronicBallot

using PeaceCypher: CypherSuite, Signer, Secret, Layer, secure, id

#abstract type Layer end
#function secure end

using Multiplexers
using Sockets

struct Regulation
    N::UInt8
    M::UInt8
    metadata::Vector{UInt8}
end

struct Ballot
    metadata::Vector{UInt8}
    votes::Array{UInt8,2}
end

abstract type Officer end

function regulation end
function audit! end


##### For Debugging #####

import Base.sync_varname
import Base.@async

macro async(expr)

    tryexpr = quote
        try
            $expr
        catch err
            @warn "error within async" exception=err # line $(__source__.line):
            @show stacktrace(catch_backtrace())
        end
    end

    thunk = esc(:(()->($tryexpr)))

    var = esc(sync_varname)
    quote
        local task = Task($thunk)
        if $(Expr(:isdefined, var))
            push!($var, task)
        end
        schedule(task)
        task
    end
end

const OPEN = UInt8(0)

function stack(io::IO,msg::Vector{UInt8})
    frontbytes = reinterpret(UInt8,Int16[length(msg)])
    item = UInt8[frontbytes...,msg...]
    write(io,item)
end

function unstack(io::IO)
    sizebytes = [read(io,UInt8),read(io,UInt8)]
    size = reinterpret(Int16,sizebytes)[1]
    
    msg = UInt8[]
    for i in 1:size
        push!(msg,read(io,UInt8))
    end
    return msg
end

####### BallotBox #######

struct Mix
    port
    id
    crypto::CypherSuite
end

function Sockets.connect(mix::Mix)
    layer = Layer(mix.crypto, mix.id)
    mixsocket = connect(mix.port)
    mixsl = secure(mixsocket, layer)
    return mixsl
end

function serve(secureserversocket::IO, ballotmember::Layer)
    N = read(secureserversocket,UInt8)
    M = read(secureserversocket,UInt8) 
    
    mux = Multiplexer(secureserversocket,N)

    susersockets = []
    for i in 1:N
        securesocket = secure(mux.lines[i],ballotmember)
        push!(susersockets,securesocket)
    end
    
    messages = UInt8[]
    for i in 1:N
        write(susersockets[i],OPEN)

        msg = unstack(susersockets[i])  ### One needs to give a msg type here. ID
        
        @assert length(msg) == M

        push!(messages,msg...)
    end
    close(mux)

    shapedmessages = reshape(messages,(M,N))

    ### I need to sort whoole collumns
    #sort!(shapedmessages, dims=2) # We may need to look into it
    sortedmessages = sortslices(shapedmessages, dims=2)
    stack(secureserversocket, reshape(sortedmessages,:))
end


function serve(mix::Mix, signer::Union{Signer, Secret})
    @assert mix.id == id(signer) 
    layer = Layer(mix.crypto, signer)

    server = listen(mix.port)

    while true
        client = secure(accept(server), layer)
        
        @async while isopen(client)
            serve(client, layer)
        end
    end
end


struct GateKeeper
    port
    id
    crypto::CypherSuite
    mix::Mix
end

function run(b::Regulation, usersockets::Vector{IO}, secureroutersocket::IO)
    N, M, metadata = b.N, b.M, b.metadata

    write(secureroutersocket,UInt8[N,M])
    
    mux = Multiplexer(secureroutersocket,usersockets)
    wait(mux)
    
    messages = unstack(secureroutersocket) ### A single list of bytes.

    ballot = reshape(messages,(M,N)) 

    signatures = Vector{UInt8}[]
    
    ### Grouping of data. 
    ### Perhaps that could be done with in a Sockets layer which 
    ### would only send data if flushed!
    ### The flush may be done automatically when one reads a byte
    io = IOBuffer()
    stack(io,metadata)
    stack(io,messages)
    rawballot = take!(io)

    for i in 1:N
        write(usersockets[i], rawballot)
        s = unstack(usersockets[i]) ### One should verify also the signatures
        push!(signatures, s)
    end

    ### User then can use metadata to form a Braid one needs
    return Ballot(metadata, ballot), signatures
end


function serve!(gk::GateKeeper, ar::Officer, signer::Union{Signer, Secret})

    @assert id(signer) == gk.id

    mix = connect(gk.mix)
    server = listen(gk.port)
    gatemember = Layer(gk.crypto, signer, ar)
    

    while true

        config = regulation(ar)

        usersockets = IO[]

        while length(usersockets) < config.N
            connection = accept(server)
            secureusersocket = secure(connection, gatemember)
            push!(usersockets, secureusersocket)
            #lock(ar, id(secureusersocket))
        end

        ### Also a partial set of signatures could be returned
        ### In that way it would be possible to figure out who did not sign the ballot
        ### and whether that happens to be a consistent behaviour which can be qualified as DDOS attack
        ballot, signatures = run(config, usersockets, mix)

        ### shall it actually error?
        audit!(ar, ballot, signatures)
    end
end


function vote(port, membergate::Layer, memberballot::Layer, msg::Vector{UInt8}, sign::Function)
    securesocket = secure(connect(port),membergate)
    sroutersocket = secure(securesocket,memberballot)
    
    @assert read(sroutersocket,UInt8)==OPEN
    stack(sroutersocket,msg)

    metadata = unstack(securesocket)
    rawballot = unstack(securesocket)

    M = length(msg)
    
    @assert mod(length(rawballot),M) == 0
    N = div(length(rawballot),M)
    
    ballot = reshape(rawballot,(M,N)) 

    s = sign(Ballot(metadata,ballot))
    stack(securesocket,s) 
end

function vote(msg::Vector{UInt8}, gk::GateKeeper, s::Union{Signer, Secret}, sign::Function)
    membergate = Layer(gk.crypto, s, gk.id)
    memberballot = Layer(gk.mix.crypto, gk.mix.id)
    return vote(gk.port, membergate, memberballot, msg, sign)
end


export Mix, GateKeeper, Officer, Ballot, Regulation, vote

end 
