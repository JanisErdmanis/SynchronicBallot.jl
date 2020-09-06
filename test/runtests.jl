using SynchronicBallot
using CryptoGroups
using CryptoSignatures
using DiffieHellman
using Sockets
using SecureIO
using Pkg.TOML

# import Serialization
# import SecureIO.SecureSocket
# SecureSocket(socket::TCPSocket,key) = SecureSocket(Socket(socket,Serialization.serialize,Serialization.deserialize),key)

import Base.Dict
hash(x::AbstractString) = BigInt(Base.hash(x))

function chash(envelope1::Vector{UInt8},envelope2::Vector{UInt8},key::BigInt) 
    str = "$(String(copy(envelope1))) $(String(copy(envelope2))) $key"
    inthash = hash(str)
    strhash = string(inthash,base=16)
    return Vector{UInt8}(strhash)
end

id(s) = hash("$(s.pubkey)")

function wrapsigned(value::BigInt,signer::Signer)
    signature = DSASignature(hash("$value"),signer)
    signaturedict = Dict(signature)
    dict = Dict("value"=>string(value,base=16),"signature"=>signaturedict)
    io = IOBuffer()
    TOML.print(io,dict)
    return take!(io)
end

function unwrapsigned(envelope::Vector{UInt8})
    dict = TOML.parse(String(copy(envelope)))
    value = parse(BigInt,dict["value"],base=16)
    signature = DSASignature{BigInt}(dict["signature"])
    @assert verify(signature,G) && signature.hash==hash("$value")
    return value, id(signature)
end

wrapmsg(value::BigInt) = Vector{UInt8}(string(value,base=16))
unwrapmsg(envelope::Vector{UInt8}) = parse(BigInt,String(copy(envelope)),base=16), nothing

function rngint(len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(min_n:max_n)
    end
    return rand(1:max_n)
end

Signature(data,signer) = DSASignature(hash("$data"),signer)

### The sign function ofcourse also depends on the message
function sign(metadata::Vector{UInt8},ballot::Array{UInt8,2},signer::Signer)
    h = hash("$metadata $ballot")
    signature = DSASignature(h,signer)
    sdict = Dict(signature)
    io = IOBuffer()
    TOML.print(io,sdict)
    return take!(io)
end

import CryptoSignatures.DSASignature

function DSASignature{BigInt}(bytes::Vector{UInt8})
    sdict = TOML.parse(String(copy(bytes)))
    return DSASignature{BigInt}(sdict)
end


struct SocketConfig <: Layer
    id ### Theese list approved ids
    dh::DH
    SecureSocket
end

function _secure(socket::IO, sc::SocketConfig)
    key,id = diffiehellman(socket,sc.dh)
    @assert id in sc.id "$id not in $(sc.id)"

    sroutersocket = sc.SecureSocket(socket,key)
    return sroutersocket
end
import Base.LibuvStream

SynchronicBallot.secure(socket::LibuvStream,sc::SocketConfig) = _secure(socket,sc)
SynchronicBallot.secure(socket::IO,sc::SocketConfig) = _secure(socket,sc)


import Base.in
in(x::Nothing,y::Nothing) = true



# The essentials of the protocol
include("core.jl")

# Some higher order configuration
include("daemons.jl")
