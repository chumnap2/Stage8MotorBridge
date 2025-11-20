#!/usr/bin/env python3
from pyvesc.VESC import VESC  # Correct import for official pyvesc 1.x
import time

# Connect to your VESC
vesc = VESC("/dev/ttyACM0")

try:
    print("➡️ Spinning motor at 0.1 duty for 2s")
    vesc.set_duty_cycle(0.1)
    time.sleep(2)

    print("➡️ Increasing to 0.3 duty for 2s")
    vesc.set_duty_cycle(0.3)
    time.sleep(2)

finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)
