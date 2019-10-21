struct BallotServer()
    ip
    userport
    keyport
end

function registermessage(route::BallotServer,userkey,message)
    clientside = connect(route)
    s = Serializer(clientside)
    s = Serialization.writeheader(s)

    ### Diffie-Hofman key exchange

    p,g = deserialize(s)
    b = 7

    serialize(s,Signature(mod(g^b,p),userkey))
    A = deserialize(s)
    
    if !isvalid(A)
        error("Server signature is incorrect")
    end

    key = mod(A^b,p)
    eclientside = SecretIO(clientside,key)
    ss = Serializer(eclientside)
    Serializtion.writeheader(ss)

    blockkey = deserialize(ss)

    #aprivkey, apublickey = generatekeypair()
    
    # Now the crucial part of sending apublickey anonymously
    tor = TOR()
    aclientside = connect(tor,route.ip,route.keyport)
    eaclientside = SecretIO(aclientside,blockkey)

    sss = Serializer(eaclientside)
    sss = Serialization.writeheader(sss)
    
    waitrandom(blockkey)
    serialize(sss,apublickey)
    waitrest(blockkey)
    close(tor)
    
    # Check and sign the block.

    block = deserialize(ss)
    
    if !isvalid(block,apublickey)
        error("The block did not have our sent key")
    end
    serialize(ss,BlockSignature(block,userkey))
        
    fullblock = deserialize(ss)
    if !issucesfull(fullblock)
        error("The block did not succeed. Try again.")
    end

    return fullblock
end
