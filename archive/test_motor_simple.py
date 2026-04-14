#!/usr/bin/env python3
from vesc_simple import SimpleVESC
import time

# Connect to VESC
vesc = SimpleVESC("/dev/ttyACM0")

try:
    print("➡️ Spinning motor at 0.1 duty for 3s")
    vesc.set_duty_cycle(0.1)
    time.sleep(3)

    print("➡️ Increasing to 0.3 duty for 3s")
    vesc.set_duty_cycle(0.3)
    time.sleep(3)

finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)
