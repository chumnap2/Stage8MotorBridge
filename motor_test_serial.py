#!/usr/bin/env python3
from pyvesc_working.pyvesc.VESC import VESC
import time

# Connect to VESC over serial
vesc = VESC("/dev/ttyACM1")
print("✅ Connected to VESC")

try:
    # Ramp motor safely
    print("➡️ Spinning motor at 0.1 duty for 2s")
    vesc.set_duty_cycle(0.1)
    time.sleep(2)

    print("➡️ Increasing to 0.3 duty for 2s")
    vesc.set_duty_cycle(0.3)
    time.sleep(2)

finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)

print("✅ Test complete")
