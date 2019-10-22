# First the server creates a bllotkey
### Need to add users for the testing part

skey,spubkey = generatekeypair()
bsc = BallotServerConfig(nothing,nothing,2001,nothing,nothing,skey)

ballotkey = BallotKey()
stask = @async anonymousmsg = getanonymousmsg(ballotkey,bsc)

# Now the users had received the ballotkey and uses that to send the message anonymously

bs = BallotServer("0.0.0.0",nothing,2002,nothing)


