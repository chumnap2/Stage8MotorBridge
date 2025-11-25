using Sockets
using PyCall
using Base.Threads: @spawn, sleep

println("🚀 Starting Julia MotorBridgeServer...")

# Initialize VESC via Python
vesc_mod = pyimport("vescminimal_nov20")
vesc = vesc_mod.VESC("/dev/ttyACM1")
println("✅ VESC object created and motor initialized at 0 duty")

# Start TCP server
server = listen(ip"127.0.0.1", 5555)
println("✅ TCP MotorBridgeServer listening on 127.0.0.1:5555")
sock = accept(server)
println("✅ Client connected: $sock")

# Global duty
global last_duty = 0.0
global running = true

# Thread: continuously apply last duty to VESC
@spawn begin
    while running
        try
            vesc.set_duty_cycle(last_duty)
        catch e
            println("❌ Error sending duty: $e")
        end
        sleep(0.05)  # 50 ms update rate
    end
end

# Main command loop
while true
    cmd = ""
    try
        cmd = readline(sock) |> strip
        if isempty(cmd)
            continue
        end
    catch e
        println("⚠️ Client disconnected or error: $e")
        break
    end

    println("📥 Command received: $cmd")

    if cmd == "enable"
        println("⚡ Enable received (no VESC action required)")

    elseif startswith(cmd, "duty")
        try
            duty_val = parse(Float64, split(cmd)[2])
            global last_duty
            last_duty = duty_val
            println("➡️ Updated last_duty to $last_duty")
        catch e
            println("❌ Failed to parse duty: $e")
        end

    elseif cmd == "stop"
        global last_duty
        last_duty = 0.0
        println("🔴 Stop command received, duty set to 0")

    elseif cmd == "exit"
        println("🛑 Exit command received. Shutting down server...")
        global running = false
        break

    else
        println("⚠️ Unknown command: $cmd")
    end
end

close(sock)
println("🛑 MotorBridgeServer exiting...")
