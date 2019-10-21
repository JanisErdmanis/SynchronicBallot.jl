struct BallotServerConfig
    blocksize
    userport
    keyport
    maintainerport
    serverkey
end

function ballotserver(ks::BallotServerConfig,prevblockhash)
    userserver = listen(ks.userport)
    keyserver = listen(ks.keyport)

    usersockets = Channel(20)

    @sync begin
    
        @async while true
            socket = accept(server)
            s = Serializer(socket)
            Serialization.writeheader(s)
            p,g = 23, 5
            a = 8
            @async begin
                serialize(s,(p,q))
                B = deserialize(s)
                if !isvalid(B)
                    close(socket)
                else
                    A = Signature(mod(g^a,p),ks.serverkey)
                    serialize(s,A)
                    key = mod(B^a,p)

                    secretsocket = SecretIO(socket,key)
                    ss = Serializer(secretesocket)
                    Serializtion.writeheader(ss)
                    put!(usersockets,ss)
                end
            end

            @async while true
                acc = []
                for i in 1:10
                    push!(acc,take!(usersockets))
                end

                blockkey = BlockKey()

                @sync for user in acc
                    @async serialize(user,blockkey)
                end

                anonymouskeys = []

                while deliverytime(blockey) # One could have a delay uppon the first time.
                    asocket = accept(keyserver)
                    secretsockett = SecretIO(asocket,blockkey)
                    @async begin
                        akey = deserialize(secretsockett)
                        push!(anonymouskeys,akey)
                    end
                end

                if length(anonymouskeys)!=10
                    @sync for user in acc
                        @async serialize(user,Error("Number of anonymous public keys received not equal to the block size"))
                    end
                else

                    block = Block(blockkey,anonymouskeys,prevblockhash)

                    userblocksignatures = []
                    @sync for user in acc
                        @async begin
                            serialize(user,blockkey)
                            us = deserialize(user)
                            push!(usersignatures,us)
                        end
                    end
                    
                    if isvalid(userblocksignatures) && length(userblocksignatures)==10
                        save(ks,block,userblocksignatures)
                        
                        @sync for user in acc
                            @async serialize(user,Success())
                        end
                        
                        prevblockhash = hash(block)
                    else
                        @sync for user in acc
                            @async serialize(user,Error("Block signatures were not valid"))
                        end
                    end
                end
            end
        end
    end
end
