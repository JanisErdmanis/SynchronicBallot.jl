### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.Scep256k1Group() # a bug. probably from binary going to value
#G = CryptoGroups.MODP160Group()

DHasym(key) = DH(value->wrapsigned(value,key),unwrapmsg,G,chash,() -> rngint(100))
DHasym() = DH(wrapmsg,unwrapsigned,G,chash,() -> rngint(100))

DHsym(key) =  DH(value->wrapsigned(value,key),unwrapsigned,G,chash,() -> rngint(100))

mixerkey = Signer(G)
mixerid = id(mixerkey)

gatekey = Signer(G)
gateid = id(gatekey)

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,id(user1key))
push!(userids,id(user2key))
push!(userids,id(user3key))

mixermember = SocketConfig(nothing,DHasym(mixerkey),(socket,key)->SecureSocket(socket,key))
membermixer = SocketConfig(mixerid,DHasym(),(socket,key)->SecureSocket(socket,key))

mixergate = SocketConfig(gateid,DHsym(mixerkey),(socket,key)->SecureSocket(socket,key))
gatemixer = SocketConfig(mixerid,DHsym(gatekey),(socket,key)->SecureSocket(socket,key))

membergate(memberkey) = SocketConfig(gateid,DHsym(memberkey),(socket,key)->SecureSocket(socket,key))
gatemember = SocketConfig(userids,DHsym(gatekey),(socket,key)->SecureSocket(socket,key))

### The ballotbox server does:
mixerserver = Mixer(2001,mixergate,mixermember)

### The gatekeeper does
gkserver = GateKeeper(2000,2001,UInt8(3),UInt8(4),gatemixer,gatemember,()->Vector{UInt8}("Hello World"))

### Users do:

@async vote(2000,membergate(user1key),membermixer,Vector{UInt8}("msg1"),(m,b) -> sign(m,b,user1key))
@async vote(2000,membergate(user2key),membermixer,Vector{UInt8}("msg3"),(m,b) -> sign(m,b,user2key))
@async vote(2000,membergate(user3key),membermixer,Vector{UInt8}("msg2"),(m,b) -> sign(m,b,user3key))

### After that gatekeeper gets ballot

@show take!(gkserver.ballots)

### Stopping stuff 
sleep(1)

stop(mixerserver)
stop(gkserver)
