module SynchronicBallot

abstract type Layer end
function secure end

using Multiplexers
using Sockets

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

function mixer(secureserversocket::IO,ballotmember::Layer)
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
    stack(secureserversocket,reshape(sortedmessages,:))
end

struct Mixer
    server
    daemon
end

function Mixer(port,ballotgate::Layer,ballotmember::Layer)
    server = listen(port)

    daemon = @async while true
        gksecuresocket = secure(accept(server),ballotgate)

        @async while isopen(gksecuresocket)
            mixer(gksecuresocket,ballotmember)
        end
    end

    return Mixer(server,daemon)
end

function stop(ballotbox::Mixer)
    server = ballotbox.server
    Sockets.close(server)
    @async Base.throwto(ballotbox.daemon,InterruptException())
    return nothing
end

######## GateKeeper ###########

function gatekeeper(server,secureroutersocket::IO,N::UInt8,M::UInt8,gatemember::Layer,metadata::Vector{UInt8})
    
    #serialize(secureroutersocket,N)
    write(secureroutersocket,UInt8[N,M])
    
    usersockets = IO[]

    while length(usersockets)<N
        secureusersocket = secure(accept(server),gatemember)
        push!(usersockets,secureusersocket)
    end

    mux = Multiplexer(secureroutersocket,usersockets)
    wait(mux)
    
    messages = unstack(secureroutersocket) ### A single list of bytes.

    #rawballot = messages # Currently no need to add additional abstraction

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
        write(usersockets[i],rawballot)
        s = unstack(usersockets[i]) ### One should verify also the signatures
        push!(signatures,s)
    end

    ### User then can use metadata to form a Braid one needs
    return (ballot,signatures)
end

struct GateKeeper
    N::Integer
    server # TCPServer
    mixer # Socket
    daemon # a Task
    ballots::Channel 
end

### Need to give the braid type for constructing the Braid!
### Also would accept a function which would add necesary message to the ballot
function GateKeeper(port,ballotport,N::UInt8,M::UInt8,gateballot::Layer,gatemember::Layer,metadata::Function)
    ### verify needs to use config.id to check that the correct ballotbox had been connected. 

    secureballotbox = secure(connect(ballotport),gateballot)

    server = listen(port)

    userset = Set()
    ballotch = Channel(10)

    daemon = @async while true
        m = metadata()
        ballot = gatekeeper(server,secureballotbox,N,M,gatemember,m)
        # one also adds ballotid from gateballot.id
        put!(ballotch,(m,ballot...))
    end
    
    GateKeeper(N,server,secureballotbox,daemon,ballotch)
end

function stop(gatekeeper::GateKeeper)
    server = gatekeeper.server
    close(server)
    @async Base.throwto(gatekeeper.daemon,InterruptException())
    return nothing
end

### In the user side one might also want something like anonymousconnect (or onionconnect, OnionSocket). Somehow we need to make it play nicelly with SecureIO.

### I need to pass the braid type here
### The msg should be with defined length
function vote(port,membergate::Layer,memberballot::Layer,msg::Vector{UInt8},sign::Function)
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

    s = sign(metadata,ballot)
    stack(securesocket,s) 
end

export Layer, Mixer, GateKeeper, stop, vote

end 
