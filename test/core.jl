### For simplicity we assume the same group to be ussed everywhere. 

function rngint(len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(min_n:max_n)
    end
    return rand(1:max_n)
end

G = CryptoGroups.MODP160Group()
Signature(data,signer) = DSASignature(hash("$data"),signer)

chash(envelopeA,envelopeB,key) = hash("$envelopeA $envelopeB $key")
id(s) = s.pubkey

ballotkey = Signer(G)
ballotid = id(ballotkey)

gatekey = Signer(G)
gateid = id(gatekey)

function unwrap(envelope)
    data, signature = envelope
    @assert verify(signature,G)
    @assert signature.hash==hash("$data")
    #@show data, id(signature)
    return data, id(signature)
end

function wrapdeb(data)
    #@show data
    return (data,nothing)
end

function unwrapdeb(envelope)
    #@show envelope
    return envelope
end

ballotmember = DH(data->(data,Signature(data,ballotkey)),unwrapdeb,G,chash,() -> rngint(100))
memberballot = DH(wrapdeb,unwrap,G,chash,() -> rngint(100))

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,hash(user1key.pubkey))
push!(userids,hash(user2key.pubkey))
push!(userids,hash(user3key.pubkey))

### The community could provide constructs
membergate(memberkey) = DH(data->(data,Signature(data,memberkey)),unwrap,G,chash,() -> rngint(100))
gatemember = DH(data->(data,Signature(data,gatekey)),unwrap,G,chash,() -> rngint(100))

@sync begin
    @async begin
        routers = listen(2001)
        serversocket = accept(routers)
        #try
            ballotbox(serversocket,ballotmember,randperm)
        # finally
        #     close(routers)
        # end
    end
    @async begin
        server = listen(2000)
        ballotsocket = connect(2001)
        #try 
            @show gatekeeper(server,ballotsocket,3,gatemember)
        # finally
        #     close(server)
        # end
    end
    
    @async vote(2000,"msg1",membergate(user1key),memberballot,x -> Signature(x,user1key))
    @async vote(2000,"msg2",membergate(user2key),memberballot,x -> Signature(x,user2key))
    @async vote(2000,"msg3",membergate(user3key),memberballot,x -> Signature(x,user3key))
end
