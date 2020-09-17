using SynchronicBallot
import PeaceCypher: sign
using PeaceCypher

struct BallotOfficer <: Officer
    members
    ballots
end

BallotOfficer() = BallotOfficer([], [])

SynchronicBallot.regulation(bo::BallotOfficer) = Regulation(UInt8(3), UInt8(4), Vector{UInt8}("Hello World"))

SynchronicBallot.audit!(bo::BallotOfficer, ballot::Ballot, signatures) = push!(bo.ballots, (ballot, signatures))

Base.in(id, bo::BallotOfficer) = id in bo.members

#### Now some stuff as usual 

notary = Notary()
crypto = CypherSuite(notary)

mixkey = newsigner(notary)
mixid = id(mixkey)

mix = Mix(3000, mixid, crypto)

mixtask = @async SynchronicBallot.serve(mix, mixkey)

sleep(1.)

### Now the gatekeeper

gatekey = newsigner(notary)
gateid = id(gatekey)

gk = GateKeeper(3001, gateid, crypto, mix)

bo = BallotOfficer()

gktask = @async SynchronicBallot.serve!(gk, bo, gatekey)

sleep(1.)

### Now I need to make users

user1key = newsigner(notary)
user2key = newsigner(notary)
user3key = newsigner(notary)


push!(bo.members, id(user1key))
push!(bo.members, id(user2key))
push!(bo.members, id(user3key))


@show istaskstarted(gktask)

@sync begin

    @async vote(Vector{UInt8}("msg1"), gk, user1key, b -> binary(sign(b, user1key)))
    @async vote(Vector{UInt8}("msg2"), gk, user2key, b -> binary(sign(b, user2key)))
    @async vote(Vector{UInt8}("msg3"), gk, user3key, b -> binary(sign(b, user3key)))

end

@show bo.ballots
