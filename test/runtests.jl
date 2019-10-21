using SharedBallot

# Maintainer key pair

mprivkey, mpubkey = generate(...)

# Setting up the server

serverkey, serverpubkey = generate(...)

ks = BlockServerConfig(10,2000,2001,2002,mpubkey,serverkey)
blockserver(ks,0000)

# Let's now generate users

users = []

for i in 1:15
    pirv,pub = generate(...)
    push!(users,(priv,pub))
end

# Users send their public keys to maintainer for joining the group. Thus maintainer has a list of public keys. he sends them to the keyserver.
userspub = [u[2] for u in users]

m = Maintainer(mprivkey,mpubkey)
s = KeyServer(0.0.0.0,2000,2001,2002,serverpubkey)
socket = connect(s,m)

for u in userpub
    serialize(socket,UserKey(u))
end

# Now the users asks for anonymous keys individually

for user in users
    @async begin
        s = KeyServer(0.0.0.0,2000,2001,2002,serverpubkey)
        u = User(user...)
        #akey = getanonymouskey(s,u)
        block = sendblockmessage(s,u,msg)
        # In the bloc there are entries and one can verify that his message is there
        
        # Now each user can make an anonymous signature
    end
end

# If all users are honest then maintainer can get back anonymous public key block signed by all users:

@show deserialize(socket) 
