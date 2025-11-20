# =============================================================
# VESCMotorController.jl — Minimal working template for VESC
# =============================================================
module VESCMotorController

# --- Simulated VESC MotorController ---
mutable struct MotorController
    speed::Float64        # duty or speed command
    enabled::Bool         # motor enabled/disabled
    position::Float64     # simulated position
    velocity::Float64     # simulated velocity
end

function MotorController()
    MotorController(0.0, false, 0.0, 0.0)
end

# --- Update simulation (or hook into real VESC commands) ---
function update!(mc::MotorController, dt::Float64)
    if mc.enabled
        mc.velocity = mc.speed
        mc.position += mc.velocity * dt
    else
        mc.velocity = 0.0
    end
end

# --- VESC MotorBridge ---
mutable struct MotorBridge
    controller::MotorController
end

# Instantiate a global bridge
const mb = MotorBridge(MotorController())

# --- Commands ---
function CmdSpeed!(mb::MotorBridge, speed::Float64)
    mb.controller.speed = speed
    println("✅ [VESC] Speed set to $(speed)")
end

function CmdEnable!(mb::MotorBridge, enable::Bool)
    mb.controller.enabled = enable
    println(enable ? "🟢 [VESC] Motor ENABLED" : "🔴 [VESC] Motor DISABLED")
end

function sendFeedback(mb::MotorBridge)
    return mb.controller.position, mb.controller.velocity
end

end # module
