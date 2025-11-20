using PyCall

# Import the working pyvesc module
VESCmod = pyimport("pyvesc.VESC")

# Connect to the motor
vesc = VESCmod.VESC("/dev/ttyACM0", baudrate=115200, timeout=0.05)

# Start heartbeat if not already running
try
    vesc.start_heartbeat()
catch e
    @warn "Heartbeat already running: $e"
end

# Julia-side state to track duty cycle
global current_duty = 0.0

# Safe ramp function
function safe_ramp_motor(vesc, target; ramp_time=2.0, steps=50)
    ramp_values = range(current_duty, stop=target, length=steps)
    for val in ramp_values
        vesc.set_duty_cycle(val)
        global current_duty = val
        sleep(ramp_time / steps)
    end
end

# Example motor run sequence
println("Ramping up to 50% duty...")
safe_ramp_motor(vesc, 0.5; ramp_time=3.0)

println("Holding at 50% for 2 seconds...")
sleep(2)

println("Ramping down to 0% duty...")
safe_ramp_motor(vesc, 0.0; ramp_time=2.0)

println("Motor run complete. Duty cycle is now 0%.")
