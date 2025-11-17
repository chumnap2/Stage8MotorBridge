module MotorBridgeServer

using Sockets
using Dates
using PyCall
#using Base.Threads: @sleep

# -----------------------------
# Python VESC Setup via PyCall
# -----------------------------
py"""
from pyvesc.VESC import VESC
import time
serial_port = "/dev/ttyACM0"
vesc = VESC(serial_port, baudrate=115200, timeout=0.1)
def enable_motor():
    # Add any initialization logic if needed
    pass

def disable_motor():
    # Stop motor safely
    set_motor_duty(0.0)

def set_motor_duty(duty):
    # Safe ramp-up/down: step duty by 0.05 every 0.1s
    current = 0.0
    step = 0.05
    step_time = 0.1
    # ramp up or down
    while abs(current - duty) > 0.01:
        if current < duty:
            current = min(current + step, duty)
        else:
            current = max(current - step, duty)
        vesc.set_duty_cycle(current)  # call VESC duty
        time.sleep(step_time)
"""

# Python function references
enable_motor = py"enable_motor"
disable_motor = py"disable_motor"
set_motor_duty = py"set_motor_duty"

# -----------------------------
# Motor Struct
# -----------------------------
mutable struct RealMotor
    speed::Float64
    enabled::Bool
end

motor = RealMotor(0.0, false)

# -----------------------------
# Motor Commands
# -----------------------------
function enable!(m::RealMotor)
    m.enabled = true
    enable_motor()
    println("Motor enabled ✅")
end

function disable!(m::RealMotor)
    m.enabled = false
    set_motor_duty(0.0)
    println("Motor disabled ⛔")
end

function set_speed!(m::RealMotor, duty::Float64)
    m.speed = duty
    set_motor_duty(duty)
    println("Motor duty set to ", duty)
end

# -----------------------------
# TCP Server
# -----------------------------
function run_motor_server(port::Int=9001)
    println("Starting MotorBridgeServer on port $port...")
    server = listen(port)

    while true
        sock = accept(server)
        @async handle_client(sock, motor)
    end
end

function handle_client(sock::TCPSocket, motor::RealMotor)
    try
        while !eof(sock)
            cmd = readline(sock)
            cmd = strip(cmd)
            if startswith(cmd, "enable")
                enable!(motor)
            elseif startswith(cmd, "disable")
                disable!(motor)
            elseif startswith(cmd, "set_speed")
                duty = parse(Float64, split(cmd)[2])
                set_speed!(motor, duty)
            else
                println("Unknown command: $cmd")
            end
        end
    finally
        close(sock)
    end
end

# -----------------------------
# Auto-start if run directly
# -----------------------------
if abspath(PROGRAM_FILE) == @__FILE__
    run_motor_server(9001)
end

end # module
