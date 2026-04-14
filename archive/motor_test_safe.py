#!/usr/bin/env python3
from pyvesc_working.pyvesc.VESC import VESC
import time

# --- Connect to VESC ---
VESCPORT = "/dev/ttyACM0"
print(f"🔌 Connecting to VESC at {VESCPORT} ...")
vesc = VESC(VESCPORT)
print("✅ Connected to VESC")

# --- Check firmware / status ---
try:
    fw = getattr(vesc, "firmware_version", None)
    print(f"🟢 Firmware version: {fw}")

    # If your pyvesc version supports it, check faults
    if hasattr(vesc, "get_fault_code"):
        fault = vesc.get_fault_code()
        print(f"⚠️ Fault code: {fault}")
        if fault != 0:
            print("🔹 Clearing faults")
            vesc.clear_faults()  # Only if method exists
except Exception as e:
    print("⚠️ Could not read VESC info:", e)

# --- Spin motor safely ---
try:
    for duty in [0.2, 0.4, 0.6]:
        print(f"➡️ Spinning motor at duty {duty}")
        vesc.set_duty_cycle(duty)
        time.sleep(2)

finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)
    print("✅ Test complete")
