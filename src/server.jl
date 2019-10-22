struct BallotServerConfig
    blocksize
    userport
    keyport
    maintainerport
    maintainerpubkey
    serverkey
end

function getanonymousmsg(ballotkey,ks)
    keyserver = listen(ks.keyport)

    anonymousmsg = []

    while deliverytime(ballotkey) # One could have a delay uppon the first time.
        asocket = accept(msgserver)
        secretsockett = SecretIO(asocket,ballotkey)
        @async begin
            msg = deserialize(secretsockett)
            push!(anonymousmsg,msg)
        end
    end
    
    if length(anonymousmsg)!=10
        return Error("Number of anonymous messages received not equal to the block size")
    else
        return anonymousmsg
    end
end

function maintainerserver!(userpubkeys,signedballots,ks)
    maintainerserver = listen(ks.maintainerport)

    while true
        socket = accept(maintainerserver)
        @async begin
            secretsocket = securesocket(socket, pubkey->pubkey==ks.maintainerpubkey, ks.serverkey)
            
            if iserror(secretsocket)
                println(secretsocket)
                continue
            end

            ss = Serializer(secretesocket)
            Serializtion.writeheader(ss)

            # Now public key can be received
            @async while isopen(secretsocket)
                pubkey = deserialize(ss) 
                put!(userpubkeys,pubkey)
            end
            
            @async while isopen(secretsocket)
                sb = take!(signedballots)
                serialize(ss,sb)
            end
        end
    end
end

function userserver!(usersockets,userpbkeys,ks)
    # Now I need to take out thoose keys into a set
    userserver = listen(ks.userport)

    while true
        socket = accept(userserver)
        
        @async begin
            (secretsocket, pubkey) = securesocket(socket, pubkey->pubkey in userpubkey, ks.serverkey)
            remove!(userpubkeys,pubkey)
            
            if iserror(secretsocket)
                println(secretsocket)
            else
                ss = Serializer(secretesocket)
                Serializtion.writeheader(ss)

                put!(usersockets,ss)
            end
        end
    end
end

function taken!(channel::AbstractChannel,n)
    acc = []
    for i in 1:n
        push!(acc,take!(channel))
    end
    
    return acc
end

function sendtoall(sockets,msg)
    @sync for user in sockets
        @async serialize(user,msg)
    end
end

function getballotsignatures(ballot,users)
    userballotsignatures = []
    @sync for user in users
        @async begin
            serialize(user,ballot)
            us = deserialize(user)
            push!(userballotsignatures,us)
        end
    end

    if isvalid(userblocksignatures) && length(userblocksignatures)==10
        return userballotsignatures
    else
        return Error("Signatures are not valid")
    end
end

function ballotserver(ks::BallotServerConfig,prevblockhash)
    
    signedballots = Channel(20)
    usersockets = Channel(20)
    userpubkeys = Channel(20) # A set probably is more appropriate

    @sync begin
        
        # The part which gets valid public keys from the maintainer
        @async maintainerserver!(userpubkeys,signedballots,ks)
    
        # This part waits  for all valid user sockets
        @async userserver!(usersockets,userpbkeys,ks)
        
        @async while true
            users = taken!(usersockets,10)
            ballotkey = BallotKey()
            sendtoall(users,ballotkey)

            anonymousmsg = getanonymousmsg(ballotkey,ks)
            
            
            if iserror(anonymousmsg)
                sendtoall(users,anonymousmsg)
                continue
            end

            ballot = Ballot(ballotkey,anonymousmsg,prevballothash)
            
            ballotsignatures = getballotsignatures(ballot,users)
            
            if iserror(ballotsignatures)
                sendtoall(users,ballotsignatures)
                continue
            end

            signedballot = SignedBallot(ks,ballot,ballotsignatures)

            put!(signedballots,signedballot)
            sendtoall(users,signedballot)
            prevblockhash = hash(signedballot)
        end
    end
end
