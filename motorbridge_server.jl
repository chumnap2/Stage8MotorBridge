# motorbridge_server.jl (robust-telnet-friendly) — patched to start ramp loop
using Sockets
using PyCall

# --- PyVESC setup ---
@pyimport serial
@pyimport pyvesc

println("[Julia] Connecting to VESC on /dev/ttyACM0 ...")
ser = serial.Serial("/dev/ttyACM0", 115200)

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

# --- Ramp loop task --------------------
function ramp_loop()
    step = 0.02
    delay = 0.05
    current = 0.0

    println("[Julia] Starting ramp loop...")

    try
        while true
            # debug tick to confirm loop is running
            println("[DEBUG] ramp tick: enabled=$(motor_enabled[]) target=$(target_duty[]) current=$current")

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
                    # keep motor off
                    set_duty(0.0)
                end
            end

            sleep(delay)
        end
    catch e
        println("[EMERGENCY] Ctrl+C or error in ramp loop, stopping motor... ", e)
        try
            set_duty(0.0)
        catch
        end
        rethrow(e)
    end
end

# Start ramp loop in background — <<< CRITICAL LINE ADDED
@async ramp_loop()

# --- Helper to read one line (handles CRLF from telnet) -------------------------
function read_cmd_line(sock::TCPSocket)
    # readuntil returns a Vector{UInt8} ending with the delimiter
    # it will throw EOFError if connection closes before delimiter
    bytes = readuntil(sock, UInt8('\n'))  # robust to CRLF (\r\n) from telnet
    # trim trailing CR/LF
    # convert to String (should be ASCII)
    try
        s = String(bytes)
    catch
        # if conversion fails, show hex and return empty
        hex = join(string.(bytes, base=16), " ")
        println("[Julia] Warning: non-UTF8 bytes: ", hex)
        s = ""
    end
    # Remove trailing newlines and carriage returns and whitespace
    s = chomp(s)          # removes \n or \r\n
    s = strip(s)          # removes leading/trailing whitespace
    return s
end

# --- TCP server ---
port = 5050
server = listen(ip"127.0.0.1", port)   # explicit IPv4 bind
println("[Julia] MotorBridge server listening on 127.0.0.1:$port")

while true
    sock = accept(server)
    println("[Julia] Client connected: $(getpeername(sock)) -> local=$(getsockname(sock))")
    @async begin
        try
            while !eof(sock)
                # read one command line (throws EOFError on close)
                line = nothing
                try
                    line = read_cmd_line(sock)
                catch e
                    if isa(e, EOFError)
                        println("[Julia] Client closed connection (EOF).")
                        break
                    else
                        rethrow(e)
                    end
                end

                if isempty(line)
                    # nothing meaningful
                    continue
                end

                # Print raw debug: show received string and hex bytes
                raw_bytes = Vector{UInt8}(line)
                hex = join(string.(raw_bytes, base=16, pad=2), " ")
                println("[Julia] cmd (string): '$line' | hex: $hex")

                if startswith(uppercase(line), "SET_DUTY:")
                    # allow SET_DUTY:0.4 or set_duty:0.4
                    # parse after colon
                    parts = split(line, ':', limit=2)
                    if length(parts) == 2
                        valstr = strip(parts[2])
                        try
                            val = parse(Float64, valstr)
                            target_duty[] = clamp(val, 0.0, 1.0)
                            println("[Julia] SET_DUTY -> target_duty=", target_duty[])
                        catch
                            println("[Julia] Bad SET_DUTY value: '", valstr, "'")
                        end
                    else
                        println("[Julia] Malformed SET_DUTY command: ", line)
                    end

                elseif uppercase(line) == "ENABLE"
                    motor_enabled[] = true
                    println("[Julia] ENABLE received. motor_enabled=", motor_enabled[])

                elseif uppercase(line) == "DISABLE"
                    motor_enabled[] = false
                    println("[Julia] DISABLE received. motor_enabled=", motor_enabled[])

                elseif startswith(uppercase(line), "CURRENT_DUTY:")
                    # optional telemetry echo
                    println("[Julia] telemetry:", line)

                else
                    println("[Julia] unknown command: '", line, "'")
                end
            end
        catch e
            println("[Julia] connection error: ", e)
        finally
            try
                close(sock)
            catch
            end
            println("[Julia] client disconnected")
        end
    end
end
