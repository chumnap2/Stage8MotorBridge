using PyCall

# -----------------------------
# Python VESC setup
# -----------------------------
py"""
from pyvesc.VESC import VESC
serial_port = "/dev/ttyACM1"   # <-- make sure this matches your VESC
vesc = VESC(serial_port, baudrate=115200)

def set_motor_duty(duty):
    vesc.set_duty_cycle(duty)
"""

set_motor_duty = py"set_motor_duty"

# -----------------------------
# Minimal test: spin motor at 50% duty
# -----------------------------
println("Setting motor to 0.5 duty")
set_motor_duty(0.5)

println("Holding for 3 seconds...")
sleep(3)

println("Stopping motor")
set_motor_duty(0.0)

println("Test complete ✅")
