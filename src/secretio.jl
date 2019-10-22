# Secure connection
SecretIO(socket,key) = socket

function securesocket(socket,isvalidpubkey::Function,serverkey)
    s = Serializer(socket)
    Serialization.writeheader(s)
    p,g = 23, 5
    a = 8

    serialize(s,(p,q))
    B = deserialize(s)
    
    if !isvalidsignature(B) || !isvalidpubkey(B)
        close(socket)
        return Error("Socket failed.")
    else
        A = Signature(mod(g^a,p),serverkey)
        serialize(s,A)
        key = mod(B^a,p)

        secretsocket = SecretIO(socket,key)

        return (secretsocket,B.pubkey)
    end
end

"""
This one returns a secret connection between two fixed parties.
"""
function connect(ip,port,isvalidpubkey::Function,key)
    clientside = connect(bs.ip,bs.userport)
    
    s = Serializer(clientside)
    s = Serialization.writeheader(s)

    ### Diffie-Hofman key exchange

    p,g = deserialize(s)
    b = 7

    serialize(s,Signature(mod(g^b,p),key))
    A = deserialize(s)

    if !isvalidsignature(A) || !isvalidpubkey(A)
        error("Server signature is incorrect")
    else
        key = mod(A^b,p)
        eclientside = SecretIO(clientside,key)
    
        return eclientside
    end
end
