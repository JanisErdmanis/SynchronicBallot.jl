module SharedBallot

using Sockets
using Serialization

# """
# This one returns a secure conncetion between ballot server and maintainer
# """
# connect(bs::BallotServer,m::Maintainer) = connect(bs.ip,bs.maintainerport,pubkey->pubkey==bs.serverpubkey,m.key)


# using Nettle
# using GaloisFields
# using RSA or ECC or Paillier
# using TOR
# using SecureIO

# include("messages.jl")
# include("server.jl")
# include("user.jl")
# include("maintainer.jl")

end 
