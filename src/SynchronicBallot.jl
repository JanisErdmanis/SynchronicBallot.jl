module SynchronicBallot

using DiffieHellman
using Multiplexers
using Serialization

######## So this part I would wish to take out.
using Sockets
import Sockets.connect
import Sockets.accept

struct SocketConfig
    id
    dh::DH
    SecureSocket
end

import Base.in
in(x::Nothing,y::Nothing) = true

import Base.LibuvStream

function _connect(socket,sc::SocketConfig) #id,dh::DH,SecureSocket)
    send = x-> serialize(socket,x)
    get = () -> deserialize(socket)

    key,id = diffiehellman(send,get,sc.dh)
    @assert id in sc.id "$id not in $(sc.id)"

    sroutersocket = sc.SecureSocket(socket,key)
    return sroutersocket
end
connect(socket::LibuvStream,sc::SocketConfig) = _connect(socket,sc)
connect(socket::IO,sc::SocketConfig) = _connect(socket,sc)


function _accept(socket,sc::SocketConfig) #members,dh::DH,SecureSocket)
    send = x -> serialize(socket,x)
    get = () -> deserialize(socket)

    key,id = diffiehellman(send,get,sc.dh)
    @assert id in sc.id "$id not in $(sc.id)"

    securesocket = sc.SecureSocket(socket,key) ### Here then I could give onion socket!
    return securesocket
end

accept(socket::LibuvStream,sc::SocketConfig) = _accept(socket,sc)
accept(socket::IO,sc::SocketConfig) = _accept(socket,sc)

####### BallotBox #######

function ballotbox(secureserversocket,ballotmember::SocketConfig,randperm::Function)
    N = deserialize(secureserversocket)
    
    mux = Multiplexer(secureserversocket,N)

    susersockets = []
    for i in 1:N
        securesocket = accept(mux.lines[i],ballotmember)
        push!(susersockets,securesocket)
    end
    
    messages = []
    for i in 1:N
        serialize(susersockets[i],:Open)
        msg = deserialize(susersockets[i])
        push!(messages,msg)
    end
    close(mux)

    rp = randperm(N)
    serialize(secureserversocket,messages[rp]) 
end

struct BallotBox
    server
    daemon
end

function BallotBox(port,ballotgate::SocketConfig,ballotmember::SocketConfig,randperm::Function)
    server = listen(port)

    daemon = @async while true
        gksecuresocket = accept(accept(server),ballotgate)

        @async while isopen(gksecuresocket)
            ballotbox(gksecuresocket,ballotmember,randperm)
        end
    end

    return BallotBox(server,daemon)
end

function stop(ballotbox::BallotBox)
    server = ballotbox.server
    Sockets.close(server)
    @async Base.throwto(ballotbox.daemon,InterruptException())
    return nothing
end

######## GateKeeper ###########

function gatekeeper(server,secureroutersocket,N::Integer,gatemember::SocketConfig)
    serialize(secureroutersocket,N)

    usersockets = IO[]

    while length(usersockets)<N
        secureusersocket = accept(accept(server),gatemember)
        push!(usersockets,secureusersocket)
    end

    mux = Multiplexer(secureroutersocket,usersockets)
    wait(mux)
        
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

function GateKeeper(port,ballotport,N::Integer,gateballot::SocketConfig,gatemember::SocketConfig)
    ### verify needs to use config.id to check that the correct ballotbox had been connected. 

    secureballotbox = connect(connect(ballotport),gateballot)

    server = listen(port)

    userset = Set()
    ballotch = Channel(10)

    daemon = @async while true
        ballot = gatekeeper(server,secureballotbox,N,gatemember)
        # one also adds ballotid from gateballot.id
        put!(ballotch,ballot)
    end
    
    GateKeeper(N,server,ballotbox,daemon,ballotch)
end

function stop(gatekeeper::GateKeeper)
    server = gatekeeper.server
    close(server)
    @async Base.throwto(gatekeeper.daemon,InterruptException())
    return nothing
end

### In the user side one might also want something like anonymousconnect (or onionconnect, OnionSocket). Somehow we need to make it play nicelly with SecureIO.

function vote(port,membergate::SocketConfig,memberballot::SocketConfig,msg,sign::Function) # wrap, unwrap
    securesocket = connect(connect(port),membergate)
    sroutersocket = connect(securesocket,memberballot)

    @assert deserialize(sroutersocket)==:Open
    serialize(sroutersocket,msg)
    
    messages = deserialize(securesocket)

    @assert msg in messages
    # Need to also add ballotboxid to the messages. (membergate.id and memberballot.id)

    s = sign(messages) 
    serialize(securesocket,s)
end

export SocketConfig, BallotBox, GateKeeper, stop, vote

end 
