# Let's test whether only elligible users can establish a connection

skey,spubkey = generatekeypair()
bsc = BallotServerConfig(nothing,2000,nothing,nothing,nothing,skey)

usersockets = Channel(20)
userpubkeys = Channel(20) # A set probably is more appropriate

@async userserver!(usersockets,userpubkeys,bsc)

# Users generate some public keys

puba, priva = generatekeypair()
pubb, privb = generatekeypair()

pubc, privc = generatekeypair()

pubd, privd = generatekeypair()

# The maintainer now registers three elligible users which acts as tickets

put!(userpubkeys,puba)
put!(userpubkeys,pubb)
put!(userpubkeys,pubc)

# Now a,b,c are elligible for secure connection.

sa = connect("0.0.0.0",2000,pubkey->pubkey==spubkey,priva)
sb = connect("0.0.0.0",2000,pubkey->pubkey==spubkey,privb)
sc = connect("0.0.0.0",2000,pubkey->pubkey==spubkey,privc)

# Whereas d must fail

sd = connect("0.0.0.0",2000,pubkey->pubkey==spubkey,privd) # Fails

# Furthermore user a,b,c is no longer elligible for another connection as the ticket is spent. Maintainer has full control over group of users forming a shared ballot to prevent poisoning of the protocol by dishonest users. 

sa = connect("0.0.0.0",2000,pubkey->pubkey==spubkey,priva) # Fails
