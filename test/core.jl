### For simplicity we assume the same group to be ussed everywhere. 
using SynchronicBallot: gatekeeper, ballotbox

G = CryptoGroups.MODP160Group()
Signature(data,signer) = DSASignature(hash("$data"),signer)

chash(envelopeA,envelopeB,key) = hash("$envelopeA $envelopeB $key")
id(s) = s.pubkey

function unwrap(envelope)
    data, signature = envelope
    @assert verify(signature,G)
    @assert signature.hash==hash("$data")
    return data, id(signature)
end

ballotkey = Signer(G)
ballotid = id(ballotkey)

gatekey = Signer(G)
gateid = id(gatekey)

ballotmember = DH(data->(data,Signature(data,ballotkey)),envelope->envelope,G,chash,() -> rngint(100))
memberballot = DH(data->(data,nothing),unwrap,G,chash,() -> rngint(100))

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
        try
            ballotbox(serversocket,ballotmember,randperm)
        finally
            close(routers)
        end
    end
    @async begin
        server = listen(2000)
        ballotsocket = connect(2001)
        try 
            @show gatekeeper(server,ballotsocket,3,gatemember)
        finally
            close(server)
        end
    end
    
    @async vote(2000,"msg1",membergate(user1key),memberballot,x -> Signature(x,user1key))
    @async vote(2000,"msg2",membergate(user2key),memberballot,x -> Signature(x,user2key))
    @async vote(2000,"msg3",membergate(user3key),memberballot,x -> Signature(x,user3key))
end
