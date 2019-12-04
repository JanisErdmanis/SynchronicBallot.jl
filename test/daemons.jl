### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.MODP160Group()
signdata(data,signer) = DSASignature(hash("$data"),signer)
verifydata(data,signature) = verify(signature,G) && signature.hash==hash("$data")

routerkey = Signer(G)
serverkey = Signer(G)

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,hash(user1key.pubkey))
push!(userids,hash(user2key.pubkey))
push!(userids,hash(user3key.pubkey))


### The ballotbox server does:
ballotboxcfg = BallotBoxConfig(G)
bboxserver = BallotBox(2001,ballotboxcfg,data->signdata(data,routerkey),verifydata)

### The gatekeeper does
broute = BallotBoxRoute(2001,nothing)
gkconfig = GateKeeperConfig(3,broute,G)
gkserver = GateKeeper(2000,gkconfig,data->signdata(data,serverkey),verifydata)

### Users do:
    
gk = GateKeeperRoute(2000,hash(serverkey.pubkey),hash(routerkey.pubkey))

@async vote("msg1",gk,data->signdata(data,user1key),verifydata)
@async vote("msg2",gk,data->signdata(data,user2key),verifydata)
@async vote("msg3",gk,data->signdata(data,user3key),verifydata)

### After that gatekeeper gets ballot

@show take!(gkserver.ballots)

### Stopping stuff 
stop(bboxserver)
stop(gkserver)
