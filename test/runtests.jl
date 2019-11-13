#using Tests
# Lets run DiffieHellman over network

using SharedBallot

using DiffieHellman
using CryptoGroups
using CryptoSignatures
using SecureIO

using Sockets

G = CryptoGroups.MODP160Group()

# Server
server = Signer(G)
serversign(data) = DSASignature(hash(data),server)
serverid = hash(server.pubkey)

# Maintainer
slave = Signer(G)
slavesign(data) = DSASignature(hash(data),slave)
maintainerid = hash(slave.pubkey)

### Let's assume that maintainer had contacted the server

@sync begin
    server = listen(2000)
    @async global serversocket = accept(server)
    global slavesocket = connect(2000)
end

# Server

userpubkeys = Channel(20)
routers = Channel(20)
signedballots = Channel(20)
logch = Channel(20)

verifymaintainer(d,s) = verify(d,s,G) && hash(s.pubkey)==maintainerid

@async begin
    keyserver = diffie(serversocket,serversign,verifymaintainer,G)
    secureserversocket = SecureTunnel(serversocket,keyserver)
    maintainercom(secureserversocket,userpubkeys,routers,signedballots,logch)
end

# Maintainer

keyslave = hellman(slavesocket,slavesign,(d,s)->verify(d,s,G) && hash(s.pubkey)==serverid) 
securesocket = SecureTunnel(slavesocket,keyslave)

for i in 1:15
    user = Signer(G)
    approveduser = User(user.pubkey,G)
    serialize(securesocket,approveduser,16*500)
end

# Server

@show user = take!(userpubkeys)

ballotkey = BallotKey(0,0)
ballot = Ballot(ballotkey,["hello","world","here"])
usersignatures = [1,2,3]
sb = SignedBallot(ballot,usersignatures)

put!(signedballots,sb)

# Maintainer

@show deserialize(securesocket)

