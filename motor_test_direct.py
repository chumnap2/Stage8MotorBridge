#!/usr/bin/env python3
import time
from serial import Serial
import struct
import threading

class DebugVESC:
    def __init__(self, port="/dev/ttyACM0"):
        self.ser = Serial(port, baudrate=115200, timeout=0.1)
        self._lock = threading.Lock()
        print(f"✅ Serial port {port} opened")

    def set_duty_cycle(self, duty: float):
        duty = max(min(duty, 1.0), -1.0)
        # COMM_SET_DUTY minimal packet: header 0x03, duty float32
        payload = b'\x03' + struct.pack(">f", duty)
        print(f"📤 Sending duty packet: {payload.hex()}")
        with self._lock:
            self.ser.write(payload)
            self.ser.flush()

    def stop(self):
        self.set_duty_cycle(0.0)

# ----------------------
if __name__ == "__main__":
    vesc = DebugVESC("/dev/ttyACM0")

    try:
        for duty in [0.1, 0.2, 0.3]:
            print(f"➡️ Setting duty: {duty}")
            vesc.set_duty_cycle(duty)
            time.sleep(3)
    finally:
        print("🔴 Stopping motor")
        vesc.stop()
        print("✅ Test complete")
