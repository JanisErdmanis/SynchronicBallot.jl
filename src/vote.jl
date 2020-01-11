function vote(port,msg,dhmemberserver::DH,dhmemberballot::DH,sign::Function) # wrap, unwrap
    @show "User"
    
    usersocket = connect(port)
    key,serverid = diffiehellman(x -> serialize(usersocket,x),() -> deserialize(usersocket),dhmemberserver) 
    securesocket = SecureSerializer(usersocket,key)

    sleep(3)

    # Let's verify the communication with ballotbox
    
    # @async serialize(securesocket,"Hello from membere")
    # #sleep(2)
    # @show deserialize(securesocket)

    send = x-> begin
        #@show x
        serialize(securesocket,x)
    end

    get = () -> begin
        x = deserialize(securesocket)
        #@show x
        x
    end

    # send("Hello")
    # @show get()

    @show key,ballotid = diffie(send,get,dhmemberballot)
    sroutersocket = SecureSerializer(securesocket,key)

    # Perhaps I could return id with the key!
    @assert deserialize(sroutersocket)==:Open
    serialize(sroutersocket,msg)
    
    @show messages = deserialize(securesocket)

    @assert msg in messages
    # Need to also add ballotboxid to the messages.

    s = sign(messages) 
    serialize(securesocket,s)
end

