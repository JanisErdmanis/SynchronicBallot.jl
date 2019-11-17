using Sockets

@sync begin
    ### The server
    @async let 
        server = listen(2000)
        try 
            usersocket1 = accept(server)
            usersocket2 = accept(server)
            usersocket3 = accept(server)

            println(usersocket1,"Hello")


            println(usersocket2,"World")
            println(usersocket2,"World")

            println(usersocket3,"Third user")
            println(usersocket3,"Third user")

            println(usersocket1,"Hello")
        finally
            close(server)
        end
    end
    ### Three users
    @async let 
        usersocket = connect(2000)
        @show readline(usersocket)
        @show readline(usersocket)
    end
    @async let 
        usersocket = connect(2000)
        @show readline(usersocket)
        @show readline(usersocket)
    end
    @async let 
        usersocket = connect(2000)
        @show readline(usersocket)
        @show readline(usersocket)
    end
end
