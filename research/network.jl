# We need generics which allows to establish connection between user, server and router. 

# The user connects to the server and has established a secure connection with in a usersocket. To satrt talking with router it does a following:
# + Sends a message to the router that all following messages should be redirected to the router. 
# + Starts DH proceedure with the socket and establishes a secure connection.
# + When the connection had ended the router informs the server and and user. The secure connection then is terminated and connection with server is resumed.

# A secure connection is established between the router and the server as that would help to identify when the connection had been misguided. Further on:
# + The server sends number of users expected for the connection 
# + The router demultiplexes the socket into individual ones which helps to talk with users. 
# + The router establishes DH with each of the socket.
# + When finished the router sends a termination signal - something of Terminate() type (I could also have something of the Connect(:router) thing)
# + The router then sends again messages to the server.

# The server meanwhile:
# + Establishes secure connection between users and the router (can be delayed but this is conceptionally simpler).
# + Communicates with users and router
# + Reroutes the connection of users to the router when the server had sent last message to the users. Forms a multiplex socket from all multiple sockets.
# + When all communcation wiht router had ended the multiplex socket would get closed. The router would send final result to the server.
# + The server then would continue communication with the user.

# For simplicity we could consider only a single user. That way I would not need to think about Multiplex. On the other hand I would still need to wrap data into types. Thus a tupple (1,msg) should work fine. The type would need to contain a mutable isopen field.

#using Sockets

# How to test a networking protocol where multiple paralel conncetions to a server are important. Perhaps a pipe?

function parse_file(path::AbstractString)
    code = read(path, String)
    block = Expr(:block)
    ex, i = Meta.parse(code, 1)
    while ex !== nothing
        push!(block.args, ex)
        ex, i = Meta.parse(code, i)
    end
    block
end

@eval quote 
    @sync begin
        @async let 
            try
                include("router.jl")
            finally
                close(router)
            end
        end
        @async let 
            try 
                include("server.jl")
            finally
                close(server)
            end
        end
        @async let 
            include("user.jl")
        end
        @async let 
            include("user.jl")
        end
        @async let 
            include("user.jl")
        end
    end
end
