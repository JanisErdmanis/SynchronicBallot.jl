module SharedBallot

using Sockets
using CryptoGroups
using CryptoSignatures
using DiffieHellman
using SecureIO
using SecureIO: Line, route

abstract type MaintainerMessage end
abstract type ServerMessage end
abstract type UserMessage end

# """
# This one returns a secure conncetion between ballot server and maintainer
# """
# connect(bs::BallotServer,m::Maintainer) = connect(bs.ip,bs.maintainerport,pubkey->pubkey==bs.serverpubkey,m.key)

include("maintainercom.jl")

#include("multiplexer.jl")

include("router.jl")
include("server.jl")
include("user.jl")

#include("usercom.jl")

# include("messages.jl")
# include("server.jl")
# include("user.jl")
# include("maintainer.jl")


export router, server, user

export maintainercom, BallotKey, Ballot, SignedBallot, User, Router

end 
