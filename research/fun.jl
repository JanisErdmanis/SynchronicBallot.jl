module Multiplexers

import Serialization.serialize

struct Line 
    socket
end

serialize(io::Line,msg) = serialize(io.socket,(1,msg))

export serialize, Line
    
end



module SecureIO

import Serialization.serialize

struct SecureSerializer
    socket
end

serialize(io::SecureSerializer,msg) = serialize(io.socket,("Encrypted stuff",msg))

export serialize, SecureSerializer
    
end

using Serialization
using .Multiplexers
using .SecureIO

io = IOBuffer()
line = Line(io)
secureline = SecureSerializer(line)

serialize(secureline,"Hello")
