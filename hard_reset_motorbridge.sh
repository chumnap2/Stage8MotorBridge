#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🚨 HARD RESET: wiping ALL broken code"

cp "$FILE" "${FILE}.bak_hardreset_$(date +%s)"

cat > "$FILE" << 'CODE'

module MotorBridgeServer

using Sockets
include("VESCDriver.jl")

# =========================
# GLOBAL STATE + LOCK
# =========================
const STATE_LOCK = ReentrantLock()

const STATE = Dict{Symbol, Any}(
    :vesc => nothing,
    :last_duty => 0.0,
    :last_command_time => time(),
    :running => true
)

# =========================
# INIT VESC
# =========================
function init_vesc(port::String)
    println("🔌 Connecting to VESC...")
    lock(STATE_LOCK) do
        STATE[:vesc] = VESCDriver.connect(port)
    end
    println("🔌 Connected")
end

# =========================
# TCP SERVER
# =========================
function start_server(tcp_port::Int)
    server = listen(tcp_port)
    println("📡 listening on ", tcp_port)

    @async while STATE[:running]
        sock = accept(server)
        @async handle_client(sock)
    end
end

# =========================
# CLIENT HANDLER (CLEAN)
# =========================
function handle_client(sock)
    println("🟢 CLIENT CONNECTED")

    try
        while isopen(sock) && !eof(sock)

            msg = strip(readline(sock))
            println("📨 RAW MSG = ", msg)

            val = try
                parse(Float64, msg)
            catch
                println("⚠️ bad input")
                continue
            end

            val = clamp(val, -0.3, 0.3)

            lock(STATE_LOCK) do
                STATE[:last_duty] = val
                STATE[:last_command_time] = time()
            end

            println("📥 CMD OK → ", val)
        end

    catch e
        println("❌ client error: ", e)
    end

    println("🔴 CLIENT DISCONNECTED")
    close(sock)
end

# =========================
# MOTOR LOOP
# =========================
function motor_loop()
    while STATE[:running]

        duty = 0.0
        dt = 0.0

        lock(STATE_LOCK) do
            duty = STATE[:last_duty]
            dt = time() - STATE[:last_command_time]
        end

        if dt > 2.0
            duty = 0.0
        end

        if rand() < 0.1
            println("⏱ dt=", round(dt, digits=3), " duty=", duty)
        end

        try
            if STATE[:vesc] !== nothing
                VESCDriver.set_duty(STATE[:vesc], duty)
            end
        catch e
            println("❌ motor error: ", e)
        end

        sleep(0.05)
    end
end

# =========================
# START
# =========================
function start(port="/dev/vesc", tcp_port=5555)

    println("🚀 CLEAN START")

    init_vesc(port)

    @async start_server(tcp_port)
    @async motor_loop()

    println("🔁 RUNNING")

    while true
        sleep(1)
    end
end

end # module

CODE

echo "✅ HARD RESET COMPLETE"
echo "👉 run: julia -e 'include(\"MotorBridgeServer.jl\"); using .MotorBridgeServer; MotorBridgeServer.start()'"
