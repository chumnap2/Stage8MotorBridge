using Sockets

host = "127.0.0.1"
port = 9000

sock = connect(host, port)
@async begin
    while true
        data = readline(sock)
        if startswith(data, "T:")
            pos, vel = split(data[3:end], ",")
            println("Telemetry -> Position: $pos, Velocity: $vel")
        else
            println("Server: $data")
        end
    end
end

while true
    cmd = readline(stdin)
    write(sock, cmd * "\n")
end
