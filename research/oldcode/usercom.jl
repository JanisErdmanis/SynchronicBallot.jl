# TODO:
# wait(blockey)
# roundtrip for the anonymization. 


function vote(securesocket,message)
    blockkey = deserialize(ss)

    
    # Now the crucial part of sending apublickey anonymously
    wait(blockkey) # To avoid timing analysis of the network

    tor = TOR()
    aclientside = connect(tor,route.ip,route.keyport)
    eaclientside = SecretIO(aclientside,blockkey)

    sss = Serializer(eaclientside)
    sss = Serialization.writeheader(sss)
    
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
    
    close(ss)

    return fullblock
end
