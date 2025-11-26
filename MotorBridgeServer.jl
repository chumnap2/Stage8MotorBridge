using Sockets, PyCall, Dates

# -------------------------
# Python imports
serial = pyimport("serial")
pyvesc = pyimport("pyvesc")
SetDutyCycle = pyvesc.messages.setters.SetDutyCycle
encode = pyvesc.encode

# -------------------------
# Detect VESC port
ACM_ports = filter(p -> occursin("ttyACM", p), readdir("/dev", join=true))
VESC_PORT = !isempty(ACM_ports) ? first(ACM_ports) : "/dev/ttyACM0"
println("🔌 Connecting to VESC at $VESC_PORT ...")
port = serial.Serial(VESC_PORT, 115200)
println("✅ VESC connected on $VESC_PORT")

function set_duty(d::Float64)
    vesc_duty = Int(round(clamp(d, -1.0, 1.0) * 100000))
    msg = SetDutyCycle(vesc_duty)
    packet = encode(msg)
    buf = Vector{UInt8}(packet)
    pycall(port.write, PyAny, PyCall.pybytes(buf))
    println("➡️ Duty set to $d at $(Dates.format(now(), "HH:MM:SS.sss"))")
end

# -------------------------
# TCP server
server = listen(ip"127.0.0.1", 5555)
println("✅ TCP MotorBridgeServer listening on 127.0.0.1:5555")
println("⏳ Waiting for client connection...")
client = accept(server)
println("✅ Client connected: $client")

# -------------------------
# Shared state
global running = false
global target_duty = 0.0

# -------------------------
# Motor loop thread
motor_thread = Threads.@spawn begin
    while true
        if running
            set_duty(target_duty)   # continuously apply last target duty
        end
        sleep(0.05)  # 20 Hz update
    end
end

# -------------------------
# Command loop
try
    while true
        data = readline(client)
        println("📥 Command received: $data")
        cmd = lowercase(strip(data))

        if cmd == "enable"
            global running
            running = true
            println("⚡ Motor ENABLED")

        elseif startswith(cmd, "duty ")
            parts = split(cmd, " ")
            if length(parts) == 2
                global target_duty
                target_duty = parse(Float64, parts[2])
            else
                println("⚠️ Invalid duty command format")
            end

        elseif cmd == "stop"
            global running
            running = false
            set_duty(0.0)
            println("🛑 Motor DISABLED")
            break

        else
            println("⚠️ Unknown command: $cmd")
        end
    end
finally
    println("✅ MotorBridgeServer exiting cleanly")
    set_duty(0.0)
    close(client)
    close(server)
end
