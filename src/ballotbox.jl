### Multiple ballotboxes withn single server does not seem to be something practical.

function ballotbox(secureserversocket,sign::Function,verify::Function,G)
    @show "BallotBox"
    # serversocket = accept(routers)
    # key = diffie(serversocket,serialize,deserialize,sign,verify,G)
    # secureserversocket = SecureSerializer(serversocket,key)

    N = deserialize(secureserversocket)
    
    mux = Multiplexer(secureserversocket,N)
    task = @async route(mux)
    
    susersockets = []
    for i in 1:N
        key = diffie(mux.lines[i],serialize,deserialize,sign,verify,G)
        push!(susersockets,SecureSerializer(mux.lines[i],key))
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
    gatekeeperset::Set
end

function BallotBox(port,sign::Function,verify::Function,G)
    server = listen(port)

    gatekeeperset = Set()

    # One needs to define verify with the corresponding gatekeeperset

    daemon = @async while true
        serversocket = accept(server)
        @async begin
            key = diffie(serversocket,serialize,deserialize,sign,verify,G)
            
            if iserror(key)
                error("Not valid key")
            else
                gksecuresocket = SecureSerializer(serversocket,key)
                while isopen(serversocket)
                    ballotbox(gksecuresocket,sign,verify,G)
                end
            end
        end
    end

    return BallotBox(server,daemon,gatekeeperset)
end
