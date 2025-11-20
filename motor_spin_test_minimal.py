#!/usr/bin/env python3
from pyvesc_working.pyvesc.VESC import VESC
import time

# Connect to VESC
PORT = "/dev/ttyACM1"
print(f"🔌 Connecting to VESC at {PORT} ...")
vesc = VESC(PORT)
print("✅ Connected to VESC")

try:
    # Spin motor at 0.2 duty cycle for 3 seconds
    print("➡️ Spinning motor at 0.2 duty for 3s")
    vesc.set_duty_cycle(0.2)
    time.sleep(3)

    # Increase to 0.4 duty for 3 seconds
    print("➡️ Increasing duty to 0.4 for 3s")
    vesc.set_duty_cycle(0.4)
    time.sleep(3)

finally:
    # Stop motor safely
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)

print("✅ Test complete")
