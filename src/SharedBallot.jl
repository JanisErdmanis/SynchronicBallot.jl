module SharedBallot

using CryptoGroups
using CryptoSignatures
using DiffieHellman
using SecureIO

abstract type MaintainerMessage end
abstract type ServerMessage end
abstract type UserMessage end

# """
# This one returns a secure conncetion between ballot server and maintainer
# """
# connect(bs::BallotServer,m::Maintainer) = connect(bs.ip,bs.maintainerport,pubkey->pubkey==bs.serverpubkey,m.key)

include("maintainer.jl")

# include("messages.jl")
# include("server.jl")
# include("user.jl")
# include("maintainer.jl")


export maintainercom, BallotKey, Ballot, SignedBallot, User, Router

end 
