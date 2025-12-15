using Sockets
using PyCall
using Base.Threads: @spawn, sleep

pushfirst!(PyVector(pyimport("sys")."path"), pwd())
println("🚀 Starting Julia MotorBridgeServer2 (RAW VESC, F´-ready)")

# ------------------------------------------------------------
# VESC Initialization (known working)
# ------------------------------------------------------------
vesc_mod = pyimport("vescminimal_nov20")
vesc = vesc_mod.VESC("/dev/ttyACM2")

println("✅ VESC object created and initialized at 0 duty")

# ------------------------------------------------------------
# TCP Server Setup
# ------------------------------------------------------------
HOST = ip"127.0.0.1"
PORT = 5555

server = listen(HOST, PORT)
println("✅ TCP MotorBridgeServer listening on $HOST:$PORT")

sock = accept(server)
println("✅ Client connected: $sock")

# ------------------------------------------------------------
# Global State
# ------------------------------------------------------------
global last_duty = 0.0
global running   = true

# ------------------------------------------------------------
# Safety Helpers
# ------------------------------------------------------------
function emergency_stop()
    global last_duty
    last_duty = 0.0
    try
        vesc.set_duty_cycle(0.0)
    catch e
        println("❌ Emergency stop failed: $e")
    end
    println("🔴 Emergency stop applied (duty = 0)")
end

# ------------------------------------------------------------
# Motor Update Thread (20 Hz)
# ------------------------------------------------------------
@spawn begin
    println("🔁 Motor update loop started (20 Hz)")
    while running
        try
            vesc.set_duty_cycle(last_duty)
        catch e
            println("❌ Error sending duty to VESC: $e")
        end
        sleep(0.05)   # 50 ms
    end
    println("🛑 Motor update loop stopped")
end

# ------------------------------------------------------------
# TCP Command Handler
# ------------------------------------------------------------
function handle_command(cmd::String)
    global last_duty
    cmd = strip(cmd)

    if isempty(cmd)
        return
    end

    println("📥 Command received: $cmd")

    # --------------------------------------------------------
    # F´ COMMAND: SET_DUTY <float>
    # --------------------------------------------------------
    if startswith(cmd, "SET_DUTY")
        try
            duty_val = parse(Float64, split(cmd)[2])
            duty_val = clamp(duty_val, -1.0, 1.0)

            last_duty = duty_val
            println("➡️ SET_DUTY applied: $last_duty")
        catch e
            println("❌ Failed to parse SET_DUTY: $e")
        end

    # --------------------------------------------------------
    # Legacy / manual commands (kept intentionally)
    # --------------------------------------------------------
    elseif startswith(cmd, "duty")
        try
            duty_val = parse(Float64, split(cmd)[2])
            duty_val = clamp(duty_val, -1.0, 1.0)

            last_duty = duty_val
            println("➡️ duty applied (legacy): $last_duty")
        catch e
            println("❌ Failed to parse duty: $e")
        end

    elseif cmd == "stop"
        emergency_stop()

    elseif cmd == "enable"
        println("⚡ Enable received (no action required)")

    elseif cmd == "exit"
        println("🛑 Exit command received")
        emergency_stop()
        global running = false
        return :exit

    else
        println("⚠️ Unknown command: $cmd")
    end
end

# ------------------------------------------------------------
# Main TCP Loop
# ------------------------------------------------------------
try
    while running
        cmd = readline(sock)
        result = handle_command(cmd)
        if result == :exit
            break
        end
    end
catch e
    println("⚠️ TCP error or client disconnected: $e")
finally
    emergency_stop()
    close(sock)
    println("🛑 MotorBridgeServer shutting down cleanly")
end
