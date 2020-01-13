using SynchronicBallot
using Sockets
using CryptoGroups
using CryptoSignatures
using Random
using DiffieHellman

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


