#!/usr/bin/env python3
import time
from pyvesc_working.pyvesc.VESC import VESC
import struct

def set_duty_cycle(self, duty):
    # Minimal VESC COMM_SET_DUTY packet
    duty = max(min(duty, 1.0), -1.0)  # clamp
    payload = struct.pack(">f", duty)
    print(f"📤 Writing raw duty bytes: {payload.hex()}")
    with self._lock:
        self.ser.write(payload)

def main():
    # Adjust this to match your pyvesc __init__ signature
    print("🔌 Connecting to VESC at /dev/ttyACM0 ...")
    vesc = VESC("/dev/ttyACM1")  # <-- make sure this matches your local VESC.py

    print("🟢 Connected to VESC")

    try:
        for duty in [0.1, 0.2, 0.3]:
            print(f"➡️ Setting duty cycle: {duty}")
            vesc.set_duty_cycle(duty)

            # Optional: debug print inside your pyvesc
            if hasattr(vesc, 'ser'):
                print(f"🔹 Serial bytes in buffer: {vesc.ser.out_waiting}")

            time.sleep(3)

    finally:
        print("🔴 Stopping motor")
        vesc.set_duty_cycle(0.0)
        print("✅ Test complete")

if __name__ == "__main__":
    main()
