function gatekeeper(servers,secureroutersocket,userids,N,sign,verify,G)
    @show "GateKepper"

    serialize(secureroutersocket,N)

    usersockets = IO[]

    while length(usersockets)<N
        usersocket = accept(servers)
        key = diffie(usersocket,serialize,deserialize,sign,verify,G)
        secureusersocket = SecureSerializer(usersocket,key)
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

struct BallotBoxRoute
    port ### latter also an ip
    id
end

import Sockets.connect
function connect(route::BallotBoxRoute,sign,verify)

    ballotbox = connect(route.port)
    key = hellman(ballotbox,serialize,deserialize,sign,verify)
    secureballotbox = SecureSerializer(ballotbox,key)

    return secureballotbox
end

struct GateKeeperConfig
    N::Integer
    ballot::BallotBoxRoute
    G
end

struct GateKeeper
    config::GateKeeperConfig
    server # TCPServer
    ballotbox # Socket
    daemon # a Task
    userset::Set
    ballots::Channel 
end

function GateKeeper(port,config::GateKeeperConfig,sign,verify)
    ### verify needs to use config.id to check that the correct ballotbox had been connected. 
    
    ballotbox = connect(config.ballot,sign,verify)

    server = listen(port)

    userset = Set()
    ballotch = Channel(10)

    daemon = @async while true
        ballot = gatekeeper(server,ballotbox,userset,config.N,sign,verify,config.G)
        put!(ballotch,ballot)
    end
    
    GateKeeper(config,server,ballotbox,daemon,userset,ballotch)
end

