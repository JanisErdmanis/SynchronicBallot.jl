struct Command
    head
    value
end

struct ServerConfig
    port
    maintainerid 
    signer ### Signer
    G
end

"""
Responsable to receive instructions from the maintainer. That includes:
+ elligible user public keys for the vote
+ ip addresses for the message routers
Also ballot server communicates with maintainer:
+ sending back signed ballots
+ sending back error messages in case of failure
"""
function serve(config::ServerConfig)
    server = listen(config.port)

    ### Need to define sign and verify

    apps = Dict() # each would have a port and 
    
    while true
        socket = accept(server)
        key = diffie(socket,serialize,deserialize,sign,verify,G)

        # One needs to test that the key is not an error. In that case one continues.
        
        securesocket = SecureSerializer(socket,key)
        
        while isopen(securesocket)
            cmd = deserialize(securesocket)
            
            if cmd.head==:start
                if cmd.value.head==:ballotbox
                    port,G = cmd.value.value
                    apps[port] = BallotBox(port,sign,verify,G)
                elseif cmd.value.head==:gatekeeper
                    port,config = cmd.value.value
                    apps[port] = GateKeeper(port,config,sign,verify)
                end

            elseif cmd.head==:add
                if cmd.value.head==:ballotbox
                    port,id = cmd.value.value
                    ballotbox = apps[port]
                    push!(ballotbox.gatekeeperset,id)
                else cmd.value.head==:gatekeeper
                    port,id = cmd.value.value
                    gatekeeper = apps[port]
                    push!(ballotbox.userset,id)
                end

            elseif cmd.head==:stop
                port = cmd.value
                pop!(apps,port)

            elseif cmd.head==:get
                if cmd.value.head==:ballot
                    port = cmd.value.value
                    gatekeeper = apps[port]

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
end
