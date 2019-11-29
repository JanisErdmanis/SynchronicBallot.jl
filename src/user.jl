function user(msg,serverport,serverid,routerid,sign,verify)
    @show "User"
    usersocket = connect(serverport)
    key = hellman(usersocket,serialize,deserialize,sign,verify)
    securesocket = SecureSerializer(usersocket,key)

    
    #@show deserialize(securesocket)

    #sleep(1)
    ### Let's now do DH with the router
    #@show key = hellman(securesocket,sign,verify)
    
    #@show deserialize(securesocket)
    #serialize(securesocket,("MSG from user",122121))


    # #@show deserialize(securesocket)
    # @show deserialize(securesocket)

    key = hellman(securesocket,serialize,deserialize,sign,verify)

    sroutersocket = SecureSerializer(securesocket,key)
    
    # We could also do manual encrypion

    @assert deserialize(sroutersocket)==:Open
    #serialize(sroutersocket,"Secure message form the User to Router")
    serialize(sroutersocket,msg)
    
    @show messages = deserialize(securesocket)
    #s = sign(messages) ### Some logic in between
    #serialize(securesocket,"me")
end

