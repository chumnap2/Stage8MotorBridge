#!/usr/bin/env julia

using Sockets
using Logging
using Printf

# -------------------------------------------------------
# GLOBAL MOTOR STATE
# -------------------------------------------------------
global motor_enabled        = false
global motor_speed          = 0.0          # current simulated speed
global motor_target_speed   = 0.0          # commanded speed
global motor_position       = 0.0          # simulation position
global telemetry_running    = false
global server_running       = true

# -------------------------------------------------------
# TELEMETRY LOOP (runs in separate Task)
# -------------------------------------------------------
function telemetry_loop(client)
    global motor_enabled
    global motor_speed
    global motor_target_speed
    global motor_position
    global telemetry_running

    println("📊 Starting telemetry loop...")

    telemetry_running = true

    try
        while telemetry_running
            if motor_enabled
                # simple first-order speed convergence
                motor_speed += (motor_target_speed - motor_speed) * 0.2
                motor_position += motor_speed * 0.1
            else
                motor_speed = 0.0
            end

            msg = @sprintf("T:%.3f,%.3f\n", motor_position, motor_speed)

            try
                write(client, msg)
                flush(client)
            catch
                println("⚠️ Telemetry: client disconnected.")
                break
            end

            sleep(0.1)
        end
    catch e
        println("⛔ Telemetry crashed: $e")
    end

    telemetry_running = false
    println("🛑 Telemetry loop stopped.")
end

# -------------------------------------------------------
# COMMAND PROCESSOR (main loop)
# -------------------------------------------------------
function command_loop(client)
    global motor_enabled
    global motor_speed
    global motor_target_speed
    global motor_position
    global telemetry_running
    global server_running

    while server_running
        raw = try
            readline(client)
        catch
            println("🔌 Client disconnected from command loop.")
            break
        end

        cmd = strip(raw)

        if cmd == ""
            continue
        end

        if cmd == "exit"
            println("🔌 Client requested exit.")
            break
        elseif cmd == "enable"
            global motor_enabled = true
            println("🔹 ENABLE received")
        elseif cmd == "disable"
            global motor_enabled = false
            println("🔹 DISABLE received")
        elseif startswith(cmd, "set_speed")
            parts = split(cmd)
            if length(parts) == 2
                val = parse(Float64, parts[2])
                global motor_target_speed = val
                println("🔹 Speed set to $val")
            else
                println("⚠️ Invalid set_speed command: $cmd")
            end
        else
            println("⚠️ Unknown command: $cmd")
        end
    end

    telemetry_running = false
end


# -------------------------------------------------------
# MAIN SERVER
# -------------------------------------------------------
function start_server(port=9001)
    global server_running

    println("🚀 MotorBridgeServer starting...")
    server = listen(port)
    println("Waiting for client on port $port...")

    client = accept(server)
    println("✅ Python client connected.")

    # Start telemetry in background
    @async telemetry_loop(client)

    # Process commands in main thread
    command_loop(client)

    println("🛑 MotorBridgeServer stopping...")

    try close(client) catch end
    try close(server) catch end
end

# -------------------------------------------------------
# Run server
# -------------------------------------------------------
start_server()
