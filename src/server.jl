function server(servers,routerport,routerid,userids,sign,verify,G)
    @show "Server"
    routersocket = connect(routerport)
    key = hellman(routersocket,serialize,deserialize,sign,verify)
    secureroutersocket = SecureSerializer(routersocket,key)

    #serialize(secureroutersocket,"Securelly from the server")
    ### Now let's do Diffie-Hellman procedure with permitted users

    usersockets = IO[]

    while length(usersockets)<3
        usersocket = accept(servers)
        ### Could be asyhnced. 
        key = diffie(usersocket,serialize,deserialize,sign,verify,G)
        secureusersocket = SecureSerializer(usersocket,key)
        push!(usersockets,secureusersocket)
    end

#    serialize(usersockets[1],"Hello")
#    serialize(usersockets[1],"Hello")

#    serialize(usersockets[2],"World")
#    serialize(usersockets[2],G)

#    serialize(usersockets[3],"Third user")

    #text = "On 14 October 1939, Royal Oak was anchored at Scapa Flow in Orkney, Scotland, when she was torpedoed by the German submarine U-47. Of Royal Oak's complement of 1,234 men and boys, 835 were killed that night or died later of their wounds. The loss of the outdated ship—the first of five Royal Navy battleships and battlecruisers sunk in the Second World War—did little to affect the numerical superiority enjoyed by the British navy and its Allies, but the sinking had a considerable effect on wartime morale. The raid made an immediate celebrity and war hero out of the U-boat commander, Günther Prien, who became the first German submarine officer to be awarded the Knight's Cross of the Iron Cross. Before the sinking of Royal Oak, the Royal Navy had considered the naval base at Scapa Flow impregnable to submarine attack, but U-47's raid demonstrated that the German navy was capable of bringing the war to British home waters. The shock resulted in rapid changes to dockland security and the construction of the Churchill Barriers around Scapa Flow."

    #serialize(usersockets[3],"A new message")
    # serialize(usersockets[3],text)
    #serialize(usersockets[2],G)
    
    # serialize(usersockets[1],text)
    # serialize(usersockets[2],text)
    # serialize(usersockets[3],text)

    # serialize(usersockets[1],G)
    # serialize(usersockets[2],G)
    # serialize(usersockets[3],G)


    ### Let's say if I wanted to redirect messages of User 1 how would I do that?
    # For a single excahnge that would look something as follows:
    

    # I could test this by deserialzizing what comes out of the routersocket

    #@show deserialize(secureroutersocket)
    route(usersockets,secureroutersocket)
    
    # for i in 1:3
    #     @show deserialize(usersockets[1])
    # end
end
