#using SharedBallot

using DiffieHellman
using CryptoGroups
using CryptoSignatures

#using SecureIO
using Sockets
### So first we have a maintainer

# G = CryptoGroups.MODP160Group()

# maintainer = Signer(G)
# maintainerid = hash(maintainer.pubkey)

# ### The communication 
# server = listen(2000)

# @sync begin
#     @async global serversocket = accept(server)
#     global maintainersocket = connect(2000)
# end

# @info "The maintainter sets up the server"

# server = Signer(G)
# serverid = hash(server.pubkey)



# serversign(data) = DSASignature(hash(data),server)
# verifymaintainer(d,s) = verify(d,s,G) # && hash(s.pubkey)==maintainerid

# @async keyserver = diffie(serversocket,serversign,(d,s)->verify(d,s,G),G)

# slave = Signer(G)
# slavesign(data) = DSASignature(hash(data),slave)
# keyslave = hellman(maintainersocket,slavesign,(d,s)->verify(d,s,G)) # x==serverid

# @show keyserver

# # @async keyserver = diffie(serversocket,serversign,verifymaintainer,G)
# #@async begin 
#     # keyserver = diffie(serversocket,serversign,verifymaintainer,G)
#     # @show keyserver
#     # secureserversocket = SecureTunnel(serversocket,keyserver)
#     # maintainercom(secureserversocket,userpubkeys,routers,signedballots,logch)
# #end

# #sleep(1)

# #

# # maintainersign(data) = DSASignature(hash(data),maintainer)

# # key = hellman(maintainersocket,maintainersign,verifyserver)


# # Instead of some shady User type one could send in a signatures
# # On the other hand that should be done with the maintainer

# for i in 1:15
#     user = Signer(G)
#     approveduser = User(user.pubkey,G)
#     serialize(securesocket,approveduser)
# end

# ### Let's now see from the server if that was succesful

# for pubkey in userpubkeys
#     @show pubkey
# end

# @info "Now let's test maintainer can receive signedballots"

# ### The server does

# ballotkey = BallotKey(0,0)
# ballot = Ballot(ballotkey,["hello","world","here"])

# usersignatures = [1,2,3]
# sb = SignedBallot(ballot,usersignatures)

# put!(signedballots,sb)

# ### The maintainer now can get stuff back

# @show deserialize(securesocket)
