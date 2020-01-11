function ballotbox(secureserversocket,dhballotmember::DH,randperm::Function)
    @show "BallotBox"

    @show N = deserialize(secureserversocket)
    
    mux = Multiplexer(secureserversocket,N)
    task = @async route(mux)

    susersockets = []
    for i in 1:N
        send = x -> serialize(mux.lines[i],x)
        get = () -> deserialize(mux.lines[i])

        key,unknownid = hellman(send,get,dhballotmember)
        @assert unknownid==nothing
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
end

function BallotBox(port,dhballotserver::DH,dhballotmember::DH,randperm::Function)
    server = listen(port)

    daemon = @async while true
        serversocket = accept(server)
        @async begin
            key = diffie(x->serialize(serversocket,x),()->deserialize(serversocket),dhballotserver)
            gksecuresocket = SecureSerializer(serversocket,key)
            while isopen(serversocket)
                ballotbox(gksecuresocket,dhballotmember,randperm)
            end
        end
    end

    return BallotBox(server,daemon)
end

function stop(ballotbox::BallotBox)
    server = ballotbox.server
    Sockets.close(server)
    @async Base.throwto(ballotbox.daemon,InterruptException())
end
