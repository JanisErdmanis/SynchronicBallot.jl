module SharedBallot

using Sockets
using CryptoGroups
using CryptoSignatures
using DiffieHellman

import Multiplexers: Line, route
import SecureIO: SecureSerializer

# @import Serialization,SecureIO,Multiplexers: serialize, deserialize

import Serialization
import SecureIO
import Multiplexers

serialize(io::Union{TCPSocket,IOBuffer},msg) = Serialization.serialize(io,msg)
deserialize(io::Union{TCPSocket,IOBuffer}) = Serialization.deserialize(io)

serialize(io::Line,msg) = Multiplexers.serialize(io,msg)
deserialize(io::Line) = Multiplexers.deserialize(io)

serialize(io::SecureSerializer,msg) = SecureIO.serialize(io,msg)
deserialize(io::SecureSerializer) = SecureIO.deserialize(io)

BallotIOs = Union{TCPSocket,IOBuffer,Line,SecureSerializer} 

Multiplexers.serialize(io::BallotIOs,msg) = serialize(io,msg)
Multiplexers.deserialize(io::BallotIOs) = deserialize(io)

SecureIO.serialize(io::BallotIOs,msg) = serialize(io,msg)
SecureIO.deserialize(io::BallotIOs) = deserialize(io)

#using Serialization, SecureIO, Multiplexers


#using SecureIO: Line, route

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
