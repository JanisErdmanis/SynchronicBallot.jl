struct GateKeeperRoute
    gatekeeperport
    gatekeeperid
    ballotboxset
end

import Sockets.connect
function connect(route::GateKeeperRoute,sign,verify)
    ### verify needs to take into account ballotboxset
    usersocket = connect(route.gatekeeperport)
    key = hellman(usersocket,serialize,deserialize,sign,verify)
    securesocket = SecureSerializer(usersocket,key)

    return securesocket
end

function vote(msg,route::GateKeeperRoute,sign,verify)
    @show "User"

    securesocket = connect(route,sign,verify)

    key = hellman(securesocket,serialize,deserialize,sign,verify)
    sroutersocket = SecureSerializer(securesocket,key)

    @assert deserialize(sroutersocket)==:Open
    serialize(sroutersocket,msg)
    
    messages = deserialize(securesocket)
    s = sign(messages) ### Some logic in between
    serialize(securesocket,s)
end

