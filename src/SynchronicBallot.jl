module SynchronicBallot

using Sockets
using DiffieHellman
using OnionSockets
import Multiplexers: route, forward, Multiplexer # using Multiplexers

function ballotbox(secureserversocket,dhballotmember::DH,randperm::Function)
    N = deserialize(secureserversocket)
    
    mux = Multiplexer(secureserversocket,N)
    task = @async route(mux)

    susersockets = []
    for i in 1:N
        securesocket = accept(mux.lines[i],dhballotmember)
        push!(susersockets,securesocket)
    end
    
    messages = []
    for i in 1:N
        serialize(susersockets[i],:Open)
        msg = deserialize(susersockets[i])
        push!(messages,msg)
    end
    serialize(secureserversocket,:Terminate)
    wait(task) 

    rp = randperm(N)
    serialize(secureserversocket,messages[rp]) 
end

struct BallotBox
    server
    daemon
end

function BallotBox(port,dhballotserver::DH,dhballotmember::DH,randperm::Function)
    server = listen(port)

    daemon = @async while true
        
        gksecuresocket = accept(server,nothing,dhballotserver)

        @async while isopen(gksecuresocket)
            ballotbox(gksecuresocket,dhballotmember,randperm)
        end
    end

    return BallotBox(server,daemon)
end

function stop(ballotbox::BallotBox)
    server = ballotbox.server
    Sockets.close(server)
    @async Base.throwto(ballotbox.daemon,InterruptException())
end

function gatekeeper(server,secureroutersocket,N::Integer,dhservermember::DH)
    serialize(secureroutersocket,N)

    usersockets = IO[]

    while length(usersockets)<N
        secureusersocket = accept(server,nothing,dhservermember)
        push!(usersockets,secureusersocket)
    end

    forward(usersockets,secureroutersocket)
        
    messages = deserialize(secureroutersocket)
    
    signatures = []
    
    for i in 1:N
        serialize(usersockets[i],messages)
        s = deserialize(usersockets[i]) ### One should verify also the signatures
        push!(signatures,s)
    end

    return (messages,signatures)
end

struct GateKeeper
    N::Integer
    server # TCPServer
    ballotbox # Socket
    daemon # a Task
    ballots::Channel 
end

function GateKeeper(port,ballotport,N::Integer,dhserverballot::DH,dhservermember::DH)
    ### verify needs to use config.id to check that the correct ballotbox had been connected. 

    secureballotbox = connect(ballotport,nothing,dhservermember)

    server = listen(port)

    userset = Set()
    ballotch = Channel(10)

    daemon = @async while true
        ballot = gatekeeper(server,secureballotbox,N,dhservermember)
        put!(ballotch,ballot)
    end
    
    GateKeeper(N,server,ballotbox,daemon,ballotch)
end

function stop(gatekeeper::GateKeeper)
    server = gatekeeper.server
    close(server)
    @async Base.throwto(gatekeeper.daemon,InterruptException())
end

function vote(port,msg,dhmemberserver::DH,dhmemberballot::DH,sign::Function) # wrap, unwrap
    securesocket = connect(port,nothing,dhmemberserver)

    sroutersocket = connect(securesocket,nothing,dhmemberballot)

    @assert deserialize(sroutersocket)==:Open
    serialize(sroutersocket,msg)
    
    messages = deserialize(securesocket)

    @assert msg in messages
    # Need to also add ballotboxid to the messages.

    s = sign(messages) 
    serialize(securesocket,s)
end

export BallotBox, GateKeeper, stop, vote

end 
