using Sockets

include("VESCDriver.jl")
using .VESCDriver

println("🚀 Starting MotorBridgeServer (FINAL)")

# =====================================================
# GLOBAL STATE
# =====================================================
global last_duty = 0.0
global running = true
global vesc = nothing

# =====================================================
# APPLY DUTY (STATE ONLY)
# =====================================================
function apply_duty(d)
    global last_duty
    last_duty = clamp(d, -0.3, 0.3)
    println("➡️ Updated duty = ", last_duty)
end

# =====================================================
# SEND DUTY
# =====================================================
function send_duty(duty)
    global vesc

    if vesc === nothing
        return
    end

    try
        VESCDriver.set_duty(vesc, duty)
    catch e
        println("❌ VESC send error: ", e)
    end
end

# =====================================================
# MOTOR LOOP
# =====================================================
function motor_loop()
    println("🔁 Motor loop running (20 Hz)")

    global last_duty, running

    while running
        send_duty(last_duty)
        sleep(0.05)
    end
end

# =====================================================
# TCP HANDLER (ROBUST)
# =====================================================
function handle_client(client)
    println("✅ Client connected")

    try
        while !eof(client)
            raw = readline(client)
            msg = lowercase(strip(raw))

            println("📥 ", repr(msg))

            if startswith(msg, "duty")
                parts = split(msg)

                if length(parts) >= 2
                    try
                        d = parse(Float64, parts[2])
                        apply_duty(d)
                    catch e
                        println("❌ Parse error: ", e)
                    end
                end

            elseif msg == "stop"
                apply_duty(0.0)

            elseif msg == "exit"
                global running = false
                break
            end
        end

    catch e
        println("❌ Client error: ", e)

    finally
        close(client)
        println("🔌 Client disconnected")
    end
end

# =====================================================
# MAIN
# =====================================================
function main()
    global vesc

    println("🚀 Booting MotorBridgeServer...")

    try
        vesc = VESCDriver.connect("/dev/vesc", 115200)
        VESCDriver.arm!(vesc)

        println("✅ VESC ready")

    catch e
        println("❌ VESC init failed: ", e)
        vesc = nothing
    end

    @async motor_loop()

    server = listen(IPv4("127.0.0.1"), 5555)

    println("📡 Listening on 127.0.0.1:5555")

    while running
        client = accept(server)
        @async handle_client(client)
    end
end

main()
