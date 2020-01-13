function gatekeeper(server,secureroutersocket,N::Integer,dhservermember::DH)
    #@show "GateKepper"

    serialize(secureroutersocket,N)

    usersockets = IO[]

    while length(usersockets)<N
        usersocket = accept(server)
        key,memberid = diffiehellman(x->serialize(usersocket,x),()->deserialize(usersocket),dhservermember)
        # here one asserts that memberid is in the set
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

struct GateKeeper
    N::Integer
    server # TCPServer
    ballotbox # Socket
    daemon # a Task
    ballots::Channel 
end

function GateKeeper(port,ballotport,N::Integer,dhserverballot::DH,dhservermember::DH)
    ### verify needs to use config.id to check that the correct ballotbox had been connected. 

    ballotbox = connect(ballotport)
    key,ballotid = diffiehellman(x -> serialize(ballotbox,x),() -> deserialize(ballotbox),dhservermember)
    secureballotbox = SecureSerializer(ballotbox,key)

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
