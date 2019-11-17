using Sockets

server = listen(2000)

routersocket = connect(2001)



usersocket1 = accept(server)
println(usersocket1,"Hello")
println(usersocket1,"Hello")

usersocket2 = accept(server)
println(usersocket2,"World")
println(usersocket2,"World")


usersocket3 = accept(server)
println(usersocket3,"Third user")

#println(usersocket1,"Hello")

println(usersocket3,"Third user")

