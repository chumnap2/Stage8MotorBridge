using Sockets
using PyCall

# -----------------------------
# Python VESC setup
# -----------------------------
py"""
from pyvesc.VESC import VESC
serial_port = "/dev/ttyACM1"   # verify this
vesc = VESC(serial_port, baudrate=115200)

def set_motor_duty(duty):
    vesc.set_duty_cycle(duty)
"""

set_motor_duty = py"set_motor_duty"

# -----------------------------
# Safety stop
# -----------------------------
function emergency_stop()
    try
        set_motor_duty(0.0)
        @warn "Emergency stop sent"
    catch e
        @error "Failed to stop motor" exception=e
    end
end

# -----------------------------
# TCP command handler
# -----------------------------
function handle_tcp_command(line::String)
    parts = split(strip(line))
    isempty(parts) && return

    if parts[1] == "SET_DUTY"
        duty = parse(Float64, parts[2])

        # safety clamp
        duty = clamp(duty, -1.0, 1.0)

        set_motor_duty(duty)
        @info "SET_DUTY applied" duty
    else
        @warn "Unknown command" line
    end
end

# -----------------------------
# TCP server
# -----------------------------
server = listen(IPv4("127.0.0.1"), 12345)
@info "MotorBridge TCP server listening on 127.0.0.1:12345"

while true
    sock = accept(server)
    @info "Client connected"

    try
        while isopen(sock)
            line = readline(sock)
            handle_tcp_command(line)
        end
    catch e
        @warn "Client disconnected or error" exception=e
        emergency_stop()
    finally
        close(sock)
    end
end
