#!/usr/bin/env python3
from pyvesc.VESC import VESC  # note: VESC is a class inside pyvesc.VESC
import time

# Connect to VESC
vesc = VESC("/dev/ttyACM0")
print("✅ Connected to VESC")

try:
    for duty in [0.1, 0.2, 0.3]:
        print(f"➡️ Spinning motor at duty: {duty}")
        vesc.set_duty_cycle(duty)
        time.sleep(2)
finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)

print("✅ Test complete")
