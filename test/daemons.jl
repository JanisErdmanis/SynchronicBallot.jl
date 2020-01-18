### For simplicity we assume the same group to be ussed everywhere. 
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

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,id(user1key))
push!(userids,id(user2key))
push!(userids,id(user3key))


ballotmember = SocketConfig(nothing,DH(data->(data,Signature(data,ballotkey)),envelope->envelope,G,chash,() -> rngint(100)),(socket,key)->SecureSocket(socket,key))
memberballot = SocketConfig(ballotid,DH(data->(data,nothing),unwrap,G,chash,() -> rngint(100)),(socket,key)->SecureSocket(socket,key))

ballotgate = SocketConfig(gateid,DH(data->(data,Signature(data,ballotkey)),unwrap,G,chash,()->rngint(100)),(socket,key)->SecureSocket(socket,key))
gateballot = SocketConfig(ballotid,DH(data->(data,Signature(data,gatekey)),unwrap,G,chash,()->rngint(100)),(socket,key)->SecureSocket(socket,key))

membergate(memberkey) = SocketConfig(gateid,DH(data->(data,Signature(data,memberkey)),unwrap,G,chash,() -> rngint(100)),(socket,key)->SecureSocket(socket,key))
gatemember = SocketConfig(userids,DH(data->(data,Signature(data,gatekey)),unwrap,G,chash,() -> rngint(100)),(socket,key)->SecureSocket(socket,key))

### The ballotbox server does:
bboxserver = BallotBox(2001,ballotgate,ballotmember,randperm)

### The gatekeeper does
gkserver = GateKeeper(2000,2001,3,gateballot,gatemember)

### Users do:

@async vote(2000,membergate(user1key),memberballot,"msg1",x -> Signature(x,user1key))
@async vote(2000,membergate(user2key),memberballot,"msg2",x -> Signature(x,user2key))
@async vote(2000,membergate(user3key),memberballot,"msg3",x -> Signature(x,user3key))

### After that gatekeeper gets ballot

@show take!(gkserver.ballots)

### Stopping stuff 
stop(bboxserver)
stop(gkserver)
