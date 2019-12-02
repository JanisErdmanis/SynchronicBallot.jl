skey,spubkey = generatekeypair()
bsc = BallotServerConfig(1,2000,2001,nothing,nothing,skey)

usersockets = Channel(20)
userpubkeys = Channel(20) 

@async userserver!(usersockets,userpubkeys,bsc)

# Now the user generates a key pair

ukey,upubkey = generatekeypair()

# Now server can wait for a message

put!(userpubkeys,upubkey)

user = take!(usersockets)

>84;0;0cballotkey = BallotKey()
sendtoall([user],ballotkey)

@async begin 
    msg =  getanonymousmsg(ballotkey,bsc)
    ballot = Ballot(ballotkey,msg,0)
    ballotsignatures = getballotsignatures(ballot,[user])

    signedballot = SignedBallot(bsc,ballot,ballotsignatures)
    sendtoall([user],signedballot)
end

# Now the user can send his message anonymously and receive confirmation in the form of fullballot

s = BallotServer(0.0.0.0,2000,2001,nothing,spubkey)
@show vote(bs,User(ukey,upubkey),"Hello World! (anonymous)")

