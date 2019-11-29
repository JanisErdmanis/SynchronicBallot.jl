function router(routers,serverid,sign::Function,verify::Function,G)
    @show "Router"
    serversocket = accept(routers)
    key = diffie(serversocket,serialize,deserialize,sign,verify,G)
    secureserversocket = SecureSerializer(serversocket,key)

    #@show deserialize(secureserversocket)
    
    lines = [Line(secureserversocket,i) for i in 1:3]
    task = @async route(lines,secureserversocket)
    
    
    susersockets = []
    for i in 1:3
        #serialize(lines[i],("Msg $i from router",1122))
        #@show deserialize(lines[i])
        key = diffie(lines[i],serialize,deserialize,sign,verify,G)
        push!(susersockets,SecureSerializer(lines[i],key))
    end
    

    messages = []
    for i in 1:3
        #@show typeof(susersockets[i])
        serialize(susersockets[i],:Open)
        msg = deserialize(susersockets[i])
        push!(messages,msg)
    end
    serialize(secureserversocket,:Terminate)
    wait(task)

    serialize(secureserversocket,messages) # This needs only to be reordered.
end
