abstract type MaintainerMessage end
abstract type ServerMessage end
abstract type UserMessage end

### The Types are ordered in chronological order as they appear in the prototcol
### This one maintainer sends when he wants to tell to the keyserver that user is elligible for being considered in the block.
struct Signature 
    stuff
    signature
    pbkey
end

# The server gives to the memebers a block key
struct BallotKey <: ServerMessage
    ballotkey
    tbegin
    tend
end

### Public key type is defined by cryptolibrary

struct Ballot <: ServerMessage
    block
end

struct BallotSignature <: UserMessage
    hash
    signature
    userpbkey
end

struct SignedBallot <: UserMessage
    ballot
    ballotsignatures
end

