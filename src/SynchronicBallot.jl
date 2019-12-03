module SynchronicBallot

using Sockets
using Random
using CryptoGroups
using CryptoSignatures
using DiffieHellman

import Multiplexers: Line, route, forward, Multiplexer
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


include("ballotbox.jl")
include("gatekeeper.jl")
include("server.jl")
include("vote.jl")

export ballotbox, gatekeeper, vote, serve, ServerConfig, Command, GateKeeperRoute, BallotBox, GateKeeper, BallotBoxRoute, GateKeeperConfig

end 
