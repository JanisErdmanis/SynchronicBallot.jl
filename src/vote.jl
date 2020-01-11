function vote(port,msg,dhmemberserver::DH,dhmemberballot::DH,sign::Function) # wrap, unwrap
    @show "User"
    
    usersocket = connect(port)
    key,serverid = diffiehellman(x -> serialize(usersocket,x),() -> deserialize(usersocket),dhmemberserver) 
    securesocket = SecureSerializer(usersocket,key)

    send = x-> serialize(securesocket,x)
    get = () -> deserialize(securesocket)

    key,ballotid = diffie(send,get,dhmemberballot)
    sroutersocket = SecureSerializer(securesocket,key)

    @assert deserialize(sroutersocket)==:Open
    serialize(sroutersocket,msg)
    
    messages = deserialize(securesocket)

    @assert msg in messages
    # Need to also add ballotboxid to the messages.

    s = sign(messages) 
    serialize(securesocket,s)
end

