### Multiple ballotboxes withn single server does not seem to be something practical.

function ballotbox(secureserversocket,sign::Function,verify::Function,G)
    @show "BallotBox"
    # serversocket = accept(routers)
    # key = diffie(serversocket,serialize,deserialize,sign,verify,G)
    # secureserversocket = SecureSerializer(serversocket,key)

    N = deserialize(secureserversocket)
    
    lines = [Line(secureserversocket,i) for i in 1:N]
    task = @async route(lines,secureserversocket)
    
    susersockets = []
    for i in 1:N
        key = diffie(lines[i],serialize,deserialize,sign,verify,G)
        push!(susersockets,SecureSerializer(lines[i],key))
    end
    
    messages = []
    for i in 1:N
        serialize(susersockets[i],:Open)
        msg = deserialize(susersockets[i])
        push!(messages,msg)
    end
    serialize(secureserversocket,:Terminate)
    wait(task)

    rp = randperm(N)
    serialize(secureserversocket,messages[rp]) 
end

# struct BallotBoxConfig
#     port
# end

### If there is all in the set one could accept all

### Mainatainaer can still have some open API for registrating the public key. 

struct BallotBox
    server
    daemon
    gatekeeperset::Set
end

function BallotBox(port,sign::Function,verify::Function,G)
    server = listen(port)

    gatekeeperset = Set()

    # One needs to define verify with the corresponding gatekeeperset

    daemon = @async while true
        serversocket = accept(server)
        @async begin
            key = diffie(serversocket,serialize,deserialize,sign,verify,G)
            
            if iserror(key)
                continue
            else
                gksecuresocket = SecureSerializer(serversocket,key)
                while isopen(serversocket)
                    ballotbox(gksecuresocket,sign,verify,G)
                end
            end
        end
    end

    return BallotBox(server,daemon,gatekeeperset)
end



### This part seems to be something which would bellong to the maintainers file. 


#     @show "Ballot Box loop"

#     routers = listen(port)
    
#     serverids = Set()

    
#     while true
#             cmd = deserialize(maintainer)
#             if cmd.head==:add
#                 if cmd.value.head==:gatekeeper
#                     push!(serverids,cmd.value.value)
#                 end
#             else cmd.head==:pop
#                 if cmd.value.head==:gatekeeper
#                     pop!(serverids,cmd.value.value)
#                 end
#             else
#                 serialize(maintainer,"Error. Comand $cmd is not understood by ballotbox.")
#             end
#         end

#     # serverids are also determined by the maintainer (a different one)

#     # perhaps one could just allow issue new connection if the public key is allowed at this point. 
#     # later on one could enforce one connection per gatekeeper

# end
