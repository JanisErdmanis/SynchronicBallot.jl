using SharedBallot

# Maintainer key pair

mkey, mpubkey = generatekeypair()

# Setting up the server

skey, spubkey = generatekeypair()

bsc = BallotServerConfig(10,2000,2001,2002,mpubkey,Server(skey,spubkey))
blockserver(bsc,0000)

# Let's now generate users

users = []

for i in 1:15
    pirv,pub = generatekeypair()
    push!(users,(priv,pub))
end

# Users send their public keys to maintainer for joining the group. Thus maintainer has a list of public keys. he sends them to the keyserver.
userspub = [u[2] for u in users]

m = Maintainer(mkey,mpubkey)
s = KeyServer(0.0.0.0,2000,2001,2002,spubkey)
socket = connect(s,m) ### 

for u in userpub
    serialize(socket,u)
end

# Now the users asks for anonymous keys individually

for user in users
    @async begin
        s = BallotServer(0.0.0.0,2000,2001,2002,spubkey)
        fullballot = vote(s,User(user),msg)
    end
end

# If all users are honest then maintainer can get back anonymous public key block signed by all users:

@show deserialize(socket) 
