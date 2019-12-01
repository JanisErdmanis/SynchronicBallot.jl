#include("maintainercom.jl")
#include("usercom.jl")

# I need to test that user can establish connection with server and also with router
# A spetial type for forwarded messages is necessary to easally establish conection through the server with the router
# I need multiplexer and demultiplexer to deal with multiple user connections. 
# So first let's forget about security and let's focus on forwarding. 
# If the same packets flow from User to Server as from user to Router then ISP sees who is connected to the router. 
# The connection however needs to go through the Server to see integrity of the system, to prevent Router being expossed to DDOS attacks. 

using SharedBallot
using Sockets
using CryptoGroups
using CryptoSignatures

### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.MODP160Group()
signdata(data,signer) = DSASignature(hash("$data"),signer)
verifydata(data,signature) = verify(signature,G) && signature.hash==hash("$data")

routerkey = Signer(G)
serverkey = Signer(G)

### Testing signatures
# data = (2324234234,"Hello World")
# signature = signdata(data,routerkey)
# @show verifydata(data,signature)
###

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
        try
            ballotbox(routers,hash(serverkey.pubkey),data->signdata(data,routerkey),verifydata,G)
        finally
            close(routers)
        end
    end
    @async begin
        servers = listen(2000)
        try 
            gatekeeper(servers,2001,hash(routerkey.pubkey),userids,data->signdata(data,serverkey),verifydata,G)
        finally
            close(servers)
        end
    end
    @async vote("msg1",2000,hash(serverkey.pubkey),hash(routerkey.pubkey),data->signdata(data,user1key),verifydata)
    @async vote("msg2",2000,hash(serverkey.pubkey),hash(routerkey.pubkey),data->signdata(data,user2key),verifydata)
    @async vote("msg3",2000,hash(serverkey.pubkey),hash(routerkey.pubkey),data->signdata(data,user3key),verifydata)
end
