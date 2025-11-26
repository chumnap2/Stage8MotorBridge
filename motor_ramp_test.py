#!/usr/bin/env python3
import serial
import time
from pyvesc import SetDutyCycle, encode_request

PORT = "/dev/ttyACM1"
BAUD = 115200

RAMP_STEPS = 10
RAMP_DELAY = 0.2
TARGET_DUTY = 0.5
HOLD_TIME = 2

print(f"🔌 Connecting to VESC at {PORT} ...")
ser = serial.Serial(PORT, BAUD, timeout=0.1)
print("✅ Connected to VESC")

def send_duty(duty):
    msg = SetDutyCycle(duty)
    packet = encode_request(msg)
    ser.write(packet)

print("🟢 Ramping up motor...")
for i in range(1, RAMP_STEPS + 1):
    duty = (TARGET_DUTY / RAMP_STEPS) * i
    print(f"➡️ Setting duty: {duty:.2f}")
    send_duty(duty)
    time.sleep(RAMP_DELAY)

print(f"⏸ Holding duty {TARGET_DUTY:.2f} for {HOLD_TIME}s")
time.sleep(HOLD_TIME)

print("🔻 Ramping down motor...")
for i in reversed(range(RAMP_STEPS + 1)):
    duty = (TARGET_DUTY / RAMP_STEPS) * i
    print(f"➡️ Setting duty: {duty:.2f}")
    send_duty(duty)
    time.sleep(RAMP_DELAY)

print("🔴 Stopping motor")
send_duty(0.0)
print("✅ Test complete")
ser.close()
