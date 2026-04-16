# ==========================================
# STAGE 9 STABLE (WORKING)
# TCP → VESC DUTY CONTROL CONFIRMED
# Date: 2026-04-16
# ==========================================
module MotorBridgeServer

using Sockets
include("VESCDriver.jl")
using .VESCDriver

# =========================
# 🔧 GLOBAL STATE
# =========================
const STATE = Dict{Symbol, Any}(
    :vesc => nothing,
    :last_duty => 0.0,
    :last_command_time => time(),
    :running => true
)

const LOCK = ReentrantLock()

# =========================
# 🔌 INIT VESC
# =========================
function init_vesc(port)
    println("🔌 Connecting to VESC...")
    STATE[:vesc] = VESCDriver.connect(port)
end

# =========================
# ⚡ MOTOR LOOP
# =========================
function motor_loop()
    println("🔁 Motor loop running (20 Hz)")

    while STATE[:running]
        try
            if STATE[:vesc] !== nothing

                # watchdog timeout (2 sec)
                if time() - STATE[:last_command_time] > 2.0
                    STATE[:last_duty] = 0.0
                end

                lock(LOCK) do
                    VESCDriver.set_duty(
                        STATE[:vesc],
                        STATE[:last_duty]
                    )
                end
            end
        catch e
            println("❌ motor error: ", e)
        end

        sleep(0.05)
    end
end

# =========================
# 🌐 CLIENT HANDLER
# =========================
function handle_client(sock)
    println("🌐 Client connected")

    try
        while isopen(sock)
            line = strip(readline(sock))

            val = parse(Float64, line)

            lock(LOCK) do
                STATE[:last_duty] = clamp(val, -0.3, 0.3)
                STATE[:last_command_time] = time()
            end

            println("📥 CMD → ", STATE[:last_duty])
        end
    catch e
        println("⚠️ client error: ", e)
    end

    println("🔌 Client disconnected")
    close(sock)
end

# =========================
# 🌐 SERVER
# =========================
function start_server(port)
    server = listen(port)
    println("📡 listening on $port")

    while true
        sock = accept(server)
        @async handle_client(sock)
    end
end

# =========================
# 🚀 START
# =========================
function start(port="/dev/vesc", tcp_port=5555)
    println("🚀 CLEAN START")

    init_vesc(port)

    @async motor_loop()

    start_server(tcp_port)
end

end # module
