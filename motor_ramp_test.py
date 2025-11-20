#!/usr/bin/env python3
from pyvesc.VESC import VESC
import time

# ---- CONFIG ----
PORT = "/dev/ttyACM1"
RAMP_STEPS = 10      # number of ramp steps
RAMP_DELAY = 0.2     # seconds between ramp steps
TARGET_DUTY = 0.5    # final duty cycle (0.0 - 1.0)
HOLD_TIME = 2        # seconds to hold target duty

# ---- CONNECT ----
print(f"🔌 Connecting to VESC at {PORT} ...")
vesc = VESC(PORT)
print("✅ Connected to VESC")

# ---- SAFELY RAMP UP ----
print("🟢 Ramping up motor...")
for i in range(1, RAMP_STEPS + 1):
    duty = (TARGET_DUTY / RAMP_STEPS) * i
    print(f"➡️ Setting duty: {duty:.2f}")
    vesc.set_duty_cycle(duty)
    time.sleep(RAMP_DELAY)

# ---- HOLD TARGET DUTY ----
print(f"⏸ Holding duty {TARGET_DUTY:.2f} for {HOLD_TIME}s")
time.sleep(HOLD_TIME)

# ---- SAFELY RAMP DOWN ----
print("🔻 Ramping down motor...")
for i in reversed(range(RAMP_STEPS + 1)):
    duty = (TARGET_DUTY / RAMP_STEPS) * i
    print(f"➡️ Setting duty: {duty:.2f}")
    vesc.set_duty_cycle(duty)
    time.sleep(RAMP_DELAY)

# ---- STOP MOTOR ----
print("🔴 Stopping motor")
vesc.set_duty_cycle(0.0)
print("✅ Test complete")
