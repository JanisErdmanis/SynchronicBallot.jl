function user(serverport,serverid,routerid,sign,verify)
    @show "User"
    usersocket = connect(serverport)
    key = hellman(usersocket,sign,verify)
    securesocket = SecureTunnel(usersocket,key)

    
    @show deserialize(securesocket)

    #sleep(1)
    ### Let's now do DH with the router
    #@show key = hellman(securesocket,sign,verify)
    
    @show deserialize(securesocket)
    serialize(securesocket,("MSG from user",122121))


    # #@show deserialize(securesocket)
    # @show deserialize(securesocket)

    @show key = hellman(securesocket,sign,verify)

    sroutersocket = SecureTunnel(securesocket,key)
    
    # We could also do manual encrypion

    @show deserialize(sroutersocket)
    serialize(sroutersocket,"Secure message form the User to Router")
end

