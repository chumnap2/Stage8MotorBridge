using PyCall

# Import your working pyvesc
VESCmod = pyimport("pyvesc.VESC")

# Connect to the motor
vesc = VESCmod.VESC("/dev/ttyACM0", baudrate=115200, timeout=0.05)

# Optional: keep a Julia-side variable for duty
current_duty = 0.0

# Define the ramp function (using Julia-side current_duty)
function safe_ramp_motor(vesc, target; ramp_time=2.0, steps=50)
    global current_duty
    ramp_values = range(current_duty, stop=target, length=steps)
    for val in ramp_values
        vesc.set_duty_cycle(val)
        current_duty = val
        sleep(ramp_time / steps)
    end
end

# Ramp up and down
safe_ramp_motor(vesc, 0.5; ramp_time=3.0)
sleep(2)
safe_ramp_motor(vesc, 0.0; ramp_time=2.0)
# 1️⃣ Stop the motor safely
vesc.set_duty_cycle(0.0)

# 2️⃣ Stop the heartbeat thread (if running)
try
    vesc.stop_heartbeat()
catch e
    @warn "Heartbeat already stopped or not started: $e"
end

# 3️⃣ Clear the Julia-side object
vesc = nothing

# 4️⃣ Force garbage collection (optional but can help)
GC.gc()
