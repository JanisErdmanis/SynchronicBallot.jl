using SynchronicBallot
using CryptoGroups
using CryptoSignatures
using Random
using DiffieHellman
using Sockets
using SecureIO

# import Serialization
# import SecureIO.SecureSocket
# SecureSocket(socket::TCPSocket,key) = SecureSocket(Socket(socket,Serialization.serialize,Serialization.deserialize),key)

function rngint(len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(min_n:max_n)
    end
    return rand(1:max_n)
end

# The essentials of the protocol
include("core.jl")

# Some higher order configuration
include("daemons.jl")


