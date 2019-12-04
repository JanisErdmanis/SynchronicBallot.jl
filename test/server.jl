### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.MODP160Group()
signdata(data,signer) = DSASignature(hash("$data"),signer)
verifydata(data,signature) = verify(signature,G) && signature.hash==hash("$data")

serverkey = Signer(G)
serverid = hash(serverkey.pubkey)

maintainerkey = Signer(G)
maintainerid = hash(maintainerkey.pubkey)

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

config = ServerConfig(1999,maintainerid,G)
server = Server(config,data->signdata(data,serverkey),verifydata)

sleep(1.0)

maintainer = Maintainer(1999,serverid,data->signdata(data,maintainerkey),verifydata)

ballotboxcfg = BallotBoxConfig(G)
start(maintainer,ballotboxcfg,2001)
push!(maintainer,serverid,2001)

broute = BallotBoxRoute(2001,serverid)
gkconfig = GateKeeperConfig(3,broute,G)
start(maintainer,gkconfig,2000)

push!(maintainer,hash(user1key.pubkey),2000)
push!(maintainer,hash(user2key.pubkey),2000)
push!(maintainer,hash(user3key.pubkey),2000)

### Users do:
sleep(1.0)
    
gk = GateKeeperRoute(2000,serverid,serverid)

@async vote("msg1",gk,data->signdata(data,user1key),verifydata)
@async vote("msg2",gk,data->signdata(data,user2key),verifydata)
@async vote("msg3",gk,data->signdata(data,user3key),verifydata)


### After that maintainer gets a ballot

sleep(5.0)

@show takeballot!(maintainer,2000)

### Now let's test closing

stop(maintainer,2001)
stop(maintainer,2000)

stop(server)
