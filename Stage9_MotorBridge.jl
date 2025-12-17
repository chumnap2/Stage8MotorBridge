using Sockets
using PyCall

# --- PyVESC setup ---
@pyimport serial
@pyimport pyvesc

const VESC_PORT = "/dev/ttyACM0"
const VESC_BAUD = 115200

println("[Julia] Connecting to VESC on $VESC_PORT ...")
ser = serial.Serial(VESC_PORT, VESC_BAUD)

function set_duty(duty::Float64)
    duty = clamp(duty, 0.0, 1.0)
    duty_int = Int(round(duty * 100000))
    try
        cmd = pyvesc.SetDutyCycle(duty_int)
        packet = pyvesc.encode(cmd)
        ser.write(Vector{UInt8}(packet))
        println("[Julia] >>> VESC DUTY SENT: $duty")
    catch e
        println("[Julia] ERROR sending duty: ", e)
    end
end

# --- Shared state ---
const motor_enabled = Ref(false)
const target_duty = Ref(0.0)

# --- Ramp loop ---
function ramp_loop()
    step = 0.02
    delay = 0.05
    current = 0.0
    println("[Julia] Starting ramp loop...")

    while true
        if motor_enabled[]
            if current < target_duty[]
                current = min(current + step, target_duty[])
            elseif current > target_duty[]
                current = max(current - step, target_duty[])
            end
            set_duty(current)
        else
            if current > 0
                current = max(current - step, 0.0)
                set_duty(current)
            else
                set_duty(0.0)
            end
        end
        sleep(delay)
    end
end

# --- Helper: read one line (telnet/CRLF robust) ---
function read_cmd_line(sock::TCPSocket)
    bytes = readuntil(sock, UInt8('\n'))
    s = try
        String(bytes)
    catch
        s = ""
    end
    s = chomp(s)
    strip(s)
end

# --- TCP server ---
function start_tcp_server(host="127.0.0.1", port=12345)
    #server = listen(ip"127.0.0.1", port)
    server = listen(ip"0.0.0.0", 12345)  # instead of 127.0.0.1
    println("[Julia] MotorBridge TCP server listening on $host:$port")

    while true
        client = accept(server)
        println("[Julia] Client connected: $(getpeername(client))")
        @async begin
            try
                while !eof(client)
                    line = read_cmd_line(client)
                    if isempty(line)
                        continue
                    end

                    # Debug output
                    println("[Julia] Received command: '$line'")

                    cmd_upper = uppercase(line)
                    if startswith(cmd_upper, "SET_DUTY:")
                        parts = split(line, ':', limit=2)
                        if length(parts) == 2
                            valstr = strip(parts[2])
                            try
                                val = parse(Float64, valstr)
                                target_duty[] = clamp(val, 0.0, 1.0)
                                println("[Julia] SET_DUTY -> target_duty=", target_duty[])
                            catch
                                println("[WARN] Bad SET_DUTY value: '$valstr'")
                            end
                        end
                    elseif cmd_upper == "ENABLE"
                        motor_enabled[] = true
                        println("[Julia] ENABLE received. motor_enabled=", motor_enabled[])
                    elseif cmd_upper == "DISABLE"
                        motor_enabled[] = false
                        println("[Julia] DISABLE received. motor_enabled=", motor_enabled[])
                    else
                        println("[WARN] Unknown command: '$line'")
                    end
                end
            catch e
                println("[ERROR] Client loop:", e)
            finally
                try close(client) catch end
                println("[Julia] Client disconnected")
            end
        end
    end
end

# --- Main ---
@async ramp_loop()          # start ramp loop in background
start_tcp_server()          # blocking, keeps main thread alive
