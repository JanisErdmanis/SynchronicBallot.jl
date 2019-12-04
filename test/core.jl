### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.MODP160Group()
signdata(data,signer) = DSASignature(hash("$data"),signer)
verifydata(data,signature) = verify(signature,G) && signature.hash==hash("$data")

routerkey = Signer(G)
serverkey = Signer(G)

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,hash(user1key.pubkey))
push!(userids,hash(user2key.pubkey))
push!(userids,hash(user3key.pubkey))

@sync begin
    @async begin
        routers = listen(2001)
        serversocket = accept(routers)
        try
            ballotbox(serversocket,data->signdata(data,routerkey),verifydata,G)
        finally
            close(routers)
        end
    end
    @async begin
        server = listen(2000)
        routersocket = connect(2001)
        try 
            @show gatekeeper(server,routersocket,userids,3,data->signdata(data,serverkey),verifydata,G)
        finally
            close(server)
        end
    end
    
    gk = GateKeeperRoute(2000,hash(serverkey.pubkey),hash(routerkey.pubkey))

    @async vote("msg1",gk,data->signdata(data,user1key),verifydata)
    @async vote("msg2",gk,data->signdata(data,user2key),verifydata)
    @async vote("msg3",gk,data->signdata(data,user3key),verifydata)
end
