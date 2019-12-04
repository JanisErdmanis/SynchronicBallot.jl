struct Command
    head
    value
end

struct ServerConfig
    port
    maintainerid 
    G
end

import Base.push!
push!(ballotbox::BallotBox,id) = push!(ballotbox.gatekeeperset,id)
push!(gatekeeper::GateKeeper,id) = push!(gatekeeper.userset,id)

struct Server
    config::ServerConfig
    server
    daemon
    apps
end

"""
Responsable to receive instructions from the maintainer. That includes:
+ elligible user public keys for the vote
+ ip addresses for the message routers
Also ballot server communicates with maintainer:
+ sending back signed ballots
+ sending back error messages in case of failure
"""
function Server(config::ServerConfig,sign,verify)
    server = listen(config.port)

    ### Need to define sign and verify

    apps = Dict() # each would have a port and 
    
    daemon = @async while true
        socket = accept(server)
        key = diffie(socket,serialize,deserialize,sign,verify,config.G)

        # One needs to test that the key is not an error. In that case one continues.
        
        securesocket = SecureSerializer(socket,key)
        
        while isopen(securesocket)
            cmd = deserialize(securesocket)
            if cmd.head==:start
                if cmd.value.head==:ballotbox
                    port,config = cmd.value.value
                    apps[port] = BallotBox(port,config,sign,verify)
                elseif cmd.value.head==:gatekeeper
                    port,config = cmd.value.value
                    apps[port] = GateKeeper(port,config,sign,verify)
                end

            elseif cmd.head==:add
                port,id = cmd.value
                app = apps[port]
                push!(app,id)

            elseif cmd.head==:stop
                port = cmd.value
                stop(apps[port])
                pop!(apps,port)

            elseif cmd.head==:get
                if cmd.value.head==:ballot
                    port = cmd.value.value
                    gatekeeper = apps[port]
                    @show isready(gatekeeper.ballots)
                    if isready(gatekeeper.ballots)
                        serialize(securesocket,take!(gatekeeper.ballots))
                    else
                        serialize(securesocket,nothing)
                    end
                end
            else
                serialize(securesocket,"Error: command not recognized")
            end
        end
    end
    
    Server(config,server,daemon,apps)
end

function stop(server::Server)
    for (port,app) in server.apps
        stop(app)
    end

    s = server.server
    close(s)

    @async Base.throwto(server.daemon,InterruptException())
end

struct Maintainer
    socket
end

function Maintainer(port,serverid,sign,verify)
    socket = connect(port)
    key = hellman(socket,serialize,deserialize,sign,verify)
    securesocket = SecureSerializer(socket,key)
    return Maintainer(securesocket)
end

start(m::Maintainer,config::BallotBoxConfig,port) = serialize(m.socket,Command(:start,Command(:ballotbox,(port,config))))

start(m::Maintainer,config::GateKeeperConfig,port) = serialize(m.socket,Command(:start,Command(:gatekeeper,(port,config))))

stop(m::Maintainer,port) = serialize(m.socket,Command(:stop,port))

push!(m::Maintainer,key,port) = serialize(m.socket,Command(:add,(port,key)))

function takeballot!(m::Maintainer,port)
    cmd = Command(:get,Command(:ballot,port))
    serialize(m.socket,cmd)
    deserialize(m.socket)
end

export Maintainer,start,stop,push!,takeballot!, Server
