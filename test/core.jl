### For simplicity we assume the same group to be ussed everywhere. 
using SynchronicBallot: gatekeeper, mixer

G = CryptoGroups.MODP160Group()

mixerkey = Signer(G)
ballotid = id(mixerkey)

gatekey = Signer(G)
gateid = id(gatekey)


DHasym(key) = DH(value->wrapsigned(value,key),unwrapmsg,G,chash,() -> rngint(100))
DHasym() = DH(wrapmsg,unwrapsigned,G,chash,() -> rngint(100))

DHsym(key) =  DH(value->wrapsigned(value,key),unwrapsigned,G,chash,() -> rngint(100))

mixermember = SocketConfig(nothing,DHasym(mixerkey),(socket,key)->SecureSocket(socket,key))
membermixer = SocketConfig(ballotid,DHasym(),(socket,key)->SecureSocket(socket,key))

userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

push!(userids,id(user1key))
push!(userids,id(user2key))
push!(userids,id(user3key))

membergate(memberkey) = SocketConfig(gateid,DHsym(memberkey),(socket,key)->SecureSocket(socket,key))
gatemember = SocketConfig(userids,DHsym(gatekey),(socket,key)->SecureSocket(socket,key))

@sync begin
    @async begin
        routers = listen(2001)
        serversocket = accept(routers)
        try
            mixer(serversocket,mixermember)
        finally
            close(routers)
        end
    end
    @async begin
        server = listen(2000)
        ballotsocket = connect(2001)
        try 
            metadata = Vector{UInt8}("Hello World!")
            ballot,signatures = gatekeeper(server,ballotsocket,UInt8(3),UInt8(4),gatemember,metadata)
            
            for s in signatures
                dsasignature = DSASignature{BigInt}(s)
                @show verify(dsasignature,G)
                @show dsasignature.hash == hash("$metadata $ballot")
            end
        finally
            close(server)
        end
    end
    
    @async vote(2000,membergate(user1key),membermixer,Vector{UInt8}("msg1"),(m,b) -> sign(m,b,user1key))
    @async vote(2000,membergate(user2key),membermixer,Vector{UInt8}("msg2"),(m,b) -> sign(m,b,user2key))
    @async vote(2000,membergate(user3key),membermixer,Vector{UInt8}("msg3"),(m,b) -> sign(m,b,user3key))
end
