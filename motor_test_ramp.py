#!/usr/bin/env python3
import time
from pyvesc_working.pyvesc.VESC import VESC

# Change to your USB port
PORT = "/dev/ttyACM0"

print(f"🔌 Connecting to VESC at {PORT} ...")
vesc = VESC(PORT)
print("✅ Connected to VESC")

# Duty cycle ramp parameters
ramp_steps = 10
ramp_delay = 0.2       # seconds between steps
target_duty = 0.5

try:
    print("🟢 Ramping up motor...")
    for i in range(1, ramp_steps + 1):
        duty = target_duty * i / ramp_steps
        print(f"➡️ Setting duty: {duty:.2f}")
        vesc.set_duty_cycle(duty)
        time.sleep(ramp_delay)

    print(f"⏸ Holding duty {target_duty:.2f} for 2s...")
    time.sleep(2.0)

    print("🔻 Ramping down motor...")
    for i in reversed(range(ramp_steps + 1)):
        duty = target_duty * i / ramp_steps
        print(f"➡️ Setting duty: {duty:.2f}")
        vesc.set_duty_cycle(duty)
        time.sleep(ramp_delay)

finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)
    print("✅ Test complete")
