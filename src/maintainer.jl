### Code related for maintainer and server communication

struct User <: MaintainerMessage
    pbkey
    G::CyclicGroup
end

struct Router <: MaintainerMessage
    ip
    pbkey
    G::CyclicGroup
end

### It would be nice to actually make a roundtrip!!!
struct BallotKey <: ServerMessage
    key
    time
end

struct Ballot <: ServerMessage
    ballotkey::BallotKey
    messages
    # prevballothash # Previous ballot hash
end

struct SignedBallot <: ServerMessage
    ballot::Ballot
    usersignatures#::Array{Signature}
end



"""
Responsable to receive instructions from the maintainer. That includes:
+ elligible user public keys for the vote
+ ip addresses for the message routers
Also ballot server communicates with maintainer:
+ sending back signed ballots
+ sending back error messages in case of failure
"""
function maintainercom(securesocket,userpubkeys,routers,signedballots,logch)
    
    # !iserror(key) || return key
    # !iserror(securesocket) || return securesocket
    
    @show isopen(securesocket)

    @sync begin
        @async while isopen(securesocket)

            msg = deserialize(securesocket)
            
            if typeof(msg)==User
                put!(userpubkeys,msg)
            elseif typeof(msg)==Router
                put!(routers,msg)
            end
        end

        @async while isopen(securesocket)
            sb = take!(signedballots)
            serialize(securesocket,sb)
        end

        @async while isopen(securesocket)
            log = take!(logch)
            serialize(securesocket,log)
        end
    end
end
