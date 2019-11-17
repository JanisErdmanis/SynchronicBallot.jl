using Sockets

router = listen(2001)
serversocket = accept(router)
