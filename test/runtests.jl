using SynchronicBallot
using Sockets
using CryptoGroups
using CryptoSignatures

# The essentials of the protocol
include("core.jl")

# Some higher order configuration
include("daemons.jl")

# The main server
include("server.jl")


