function router(routers,serverid,sign::Function,verify::Function,G)
    @show "Router"
    serversocket = accept(routers)
    key = diffie(serversocket,sign,verify,G)
    secureserversocket = SecureTunnel(serversocket,key)

    @show deserialize(secureserversocket)
    
    lines = [Line(secureserversocket,i) for i in 1:3]
    task = @async route(lines,secureserversocket)
    
    
    susersockets = []
    for i in 1:3
        serialize(lines[i],("Msg $i from router",1122))
        @show deserialize(lines[i])
        key = diffie(lines[i],sign,verify,G)
        push!(susersockets,SecureTunnel(lines[i],key))
    end
    
    for i in 1:3
        #@show typeof(susersockets[i])
        serialize(susersockets[i],"Secure message from the router")
        @show deserialize(susersockets[i])
    end
    
    serialize(secureserversocket,:Terminate)
    
    wait(task)
end
