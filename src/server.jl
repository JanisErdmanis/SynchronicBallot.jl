struct BallotServerConfig
    blocksize
    userport
    keyport
    maintainerport
    maintainerpubkey
    serverkey
end

function getanonymousmsg(server,ballotkey)
    anonymousmsg = []

    while deliverytime(ballotkey) # One could have a delay uppon the first time.
        asocket = accept(msgserver)
        secretsockett = SecretIO(asocket,ballotkey)
        @async begin
            msg = deserialize(secretsockett)
            push!(anonymousmsg,msg)
        end
    end
end

function ballotserver(ks::BallotServerConfig,prevblockhash)
    userserver = listen(ks.userport)
    keyserver = listen(ks.keyport)
    maintainerserver = listen(ks.maintainerport)

    usersockets = Channel(20)

    userpubkeys = [] # A set probably is more appropriate

    @sync begin
        
        # The part which gets valid public keys from the maintainer
        @async while true
            socket = accept(maintainerserver)
            @async begin
                secretsocket = securesocket(socket, pubkey->pubkey==ks.maintainerpubkey, ks.serverkey)
                
                if iserror(secretsocket)
                    println(secretsocket)
                else
                    ss = Serializer(secretesocket)
                    Serializtion.writeheader(ss)

                    # Now public key can be received
                    while isopen(socket)
                        pubkey = deserialize(ss) 
                        push!(userpubkeys,pubkey)
                    end
                end
            end
        end
    
        # This part waits for all valid user sockets
        @async while true
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

        @async while true
            acc = []
            for i in 1:10
                push!(acc,take!(usersockets))
            end

            ballotkey = BallotKey()

            @sync for user in acc
                @async serialize(user,ballotkey)
            end

            anonymousmsg = getanonymousmsg(msgserver,ballotkey)
            
            
            if length(anonymousmsg)!=10
                @sync for user in acc
                    @async serialize(user,Error("Number of anonymous messages received not equal to the block size"))
                end
            else

                ballot = Ballot(ballotkey,anonymousmsg,prevballothash)

                userballotsignatures = []
                @sync for user in acc
                    @async begin
                        serialize(user,ballotkey)
                        us = deserialize(user)
                        push!(userballotsignatures,us)
                    end
                end
                
                if isvalid(userblocksignatures) && length(userblocksignatures)==10
                    
                    signedballot = SignedBallot(ks,ballot,userballotsignatures)
                    
                    save(signedballot)
                    
                    @sync for user in acc
                        @async serialize(user,signedballot)
                    end
                    
                    prevblockhash = hash(signedballot)
                else
                    @sync for user in acc
                        @async serialize(user,Error("Block signatures were not valid"))
                    end
                end
            end
        end
    end
end
