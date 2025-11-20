module MotorBridgeServer

using Sockets
using PyCall

# -------------------------------
# Motor parameters
const MIN_DUTY = 0.05   # minimum safe duty
const MAX_DUTY = 1.0    # maximum duty
const STEP = 0.01       # ramp step
const STEP_TIME = 0.05  # seconds per step
const SERVER_PORT = 9001

# -------------------------------
# Python VESC interface
py"""
import sys
import os

# Ensure local pyvesc_working is visible
sys.path.insert(0, os.getcwd() + "/pyvesc_working")

from pyvesc.VESC import VESC
import time

serial_port = "/dev/ttyACM1"
vesc = VESC(serial_port, baudrate=115200)
current_duty = 0.0

def enable_motor():
    global current_duty
    current_duty = 0.0
    vesc.set_duty_cycle(current_duty)
    print("Motor enabled ✅")

def disable_motor():
    global current_duty
    set_motor_duty(0.0)
    print("Motor disabled ⛔")

def set_motor_duty(target_duty):
    global current_duty
    # Clamp duty
    target_duty = max($MIN_DUTY, min($MAX_DUTY, target_duty))
    # Smooth ramp
    while abs(current_duty - target_duty) > 0.001:
        if current_duty < target_duty:
            current_duty = min(current_duty + $STEP, target_duty)
        else:
            current_duty = max(current_duty - $STEP, target_duty)
        vesc.set_duty_cycle(current_duty)
        time.sleep($STEP_TIME)
"""

# Bind Python functions
enable_motor = py"enable_motor"
disable_motor = py"disable_motor"
set_motor_duty = py"set_motor_duty"

# -------------------------------
# Julia motor abstraction
mutable struct RealMotor
    speed::Float64
    enabled::Bool
end

motor = RealMotor(0.0, false)

function enable!(m::RealMotor)
    m.enabled = true
    enable_motor()
    println("Motor enabled ✅")
end

function disable!(m::RealMotor)
    m.enabled = false
    disable_motor()
    println("Motor disabled ⛔")
end

function set_speed!(m::RealMotor, duty::Float64)
    duty = max(MIN_DUTY, min(MAX_DUTY, duty))
    m.speed = duty
    set_motor_duty(duty)
    println("Motor duty set to ", duty)
end

# -------------------------------
# TCP client handler
function handle_client(sock::TCPSocket, motor::RealMotor)
    try
        while !eof(sock)
            cmd = strip(readline(sock))
            if startswith(cmd, "enable")
                enable!(motor)
            elseif startswith(cmd, "disable")
                disable!(motor)
            elseif startswith(cmd, "set_speed")
                args = split(cmd)
                if length(args) == 2
                    duty = parse(Float64, args[2])
                    set_speed!(motor, duty)
                else
                    println("Invalid set_speed command")
                end
            else
                println("Unknown command: $cmd")
            end
        end
    finally
        close(sock)
    end
end

function run_motor_server(port::Int=SERVER_PORT)
    println("Starting MotorBridgeServer on port $port...")
    server = listen(port)
    while true
        sock = accept(server)
        @async handle_client(sock, motor)
    end
end

# -------------------------------
# Main entry point
if abspath(PROGRAM_FILE) == @__FILE__
    run_motor_server(SERVER_PORT)
end

end # module
