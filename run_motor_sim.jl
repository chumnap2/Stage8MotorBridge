using Plots

# ---------------------------
# Simulated MotorController
# ---------------------------
mutable struct MotorController
    speed::Float64
    enabled::Bool
    position::Float64
    velocity::Float64
end

function MotorController()
    MotorController(0.0, false, 0.0, 0.0)
end

function update!(mc::MotorController, dt::Float64)
    if mc.enabled
        mc.velocity = mc.speed
        mc.position += mc.velocity * dt
    else
        mc.velocity = 0.0
    end
end

# ---------------------------
# Simulated MotorBridge
# ---------------------------
mutable struct MotorBridge
    controller::MotorController
end

function CmdSpeed!(mb::MotorBridge, speed)
    mb.controller.speed = speed
    println("✅ Motor speed set to $(speed) units/s")
end

function CmdEnable!(mb::MotorBridge, enable)
    mb.controller.enabled = enable
    println(enable ? "🟢 Motor ENABLED" : "🔴 Motor DISABLED")
end

function sendFeedback(mb::MotorBridge)
    return mb.controller.position, mb.controller.velocity
end

# ---------------------------
# Global Simulation State
# ---------------------------
const mc = MotorController()
const mb = MotorBridge(mc)
const dt = 0.1

const times = Float64[]
const positions = Float64[]
const velocities = Float64[]

# ---------------------------
# Simulation Functions
# ---------------------------
function simulate!(tmax::Float64=10.0)
    println("🧩 Enabling motor...")
    CmdEnable!(mb, true)
    CmdSpeed!(mb, 1.0)

    nsteps = Int(round(tmax/dt))
    for i in 1:nsteps
        update!(mc, dt)
        pos, vel = sendFeedback(mb)
        push!(times, i*dt)
        push!(positions, pos)
        push!(velocities, vel)
        sleep(dt / 10)   # speed up simulation
    end

    println("🔴 Stopping motor...")
    CmdEnable!(mb, false)
    println("✅ Simulation complete.")
end
# ---------------------------
function plot_results()
    gr()  # ensure GR backend
    p = plot(times, positions, label="Position", xlabel="Time (s)", ylabel="Position", linewidth=2)
    plot!(p, times, velocities, label="Velocity", linewidth=2)
    display(p)
    gui()  # <-- this keeps the plot window open
end
# ---------------------------
# Auto-run if script is executed
# ---------------------------
if abspath(PROGRAM_FILE) == @__FILE__
    simulate!(10.0)
    plot_results()
end
