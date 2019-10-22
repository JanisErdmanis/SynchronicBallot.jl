using SharedBallot
using Serializer

### So first we have a maintainer

mkey,mpubkey = generatekeypair()

### The maintainer sets up a server

skey,spubkey = generatekeypair()
bsc = BallotServerConfig(nothing,nothing,nothing,2002,mpubkey,skey)

userpubkeys = Channel(20)
signedballots = Channel(20)

@async maintainerserver!(userpubkeys,signedballots,bsc)

### Now the maintainer establishes a connection with the server

socket = coonect("0.0.0.0",2002,pubkey->pubkey==spubkey,mkey)

s = Serializer(socket)
s = Serialization.writeheader(s)

for i in 1:15
    pirv,pub = generate(...)
    serialize(s,pub)
end

### Let's now see from the server if that was succesful

for pubkey in userpubkeys
    @show pubkey
end

@info "Now let's test maintainer can receive signedballots"

### The server does

ballotkey = BallotKey()
ballot = Ballot(ballotkey,["hello","ddsd","ddff"],0)
sb = SignedBallot(bsc,ballot,[0,1,2])

put!(signedballots,sb)

### The maintainer now can get stuff back

@show deserialize(s)




