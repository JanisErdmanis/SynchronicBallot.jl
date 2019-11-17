using SharedBallot: Line, connect, serialize, deserialize
using Sockets

@sync begin
    @async let
        server = listen(2014)
        try
            socket = accept(server)
            lines = [Line(socket,i) for i in 1:3]

            task = @async connect(lines,socket)


            serialize(lines[1],"Hello World")
            serialize(socket,:Terminate)
            wait(task)
        finally
            close(server)
        end
    end

    @async let
        socket = connect(2014)
        lines = [Line(socket,i) for i in 1:3]

        task = @async connect(lines,socket)
        @show deserialize(lines[1])
        serialize(socket,:Terminate)
        wait(task)
    end
end


