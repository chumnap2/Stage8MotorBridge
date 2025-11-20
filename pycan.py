#!/usr/bin/env python3
import time
import can
import struct

# ---- VESC CAN settings ----
CAN_CHANNEL = "can0"       # Your CAN interface
VESC_CAN_ID = 0x01         # CAN ID of your VESC

# ---- CAN Bus setup ----
bus = can.interface.Bus(channel=CAN_CHANNEL, bustype="socketcan")

def send_duty(duty: float):
    """
    Send a duty cycle command to the VESC over CAN.
    duty: -1.0 to 1.0
    """
    # VESC CAN protocol for SetDuty (6 bytes payload)
    # 0x00: Command ID (0x00 = SetDuty)
    cmd_id = 0x00
    # Convert float to int32 representation (4 bytes)
    duty_int = int(duty * 100000)
    duty_bytes = struct.pack(">i", duty_int)
    data = bytes([cmd_id]) + duty_bytes + bytes([0x00])
    msg = can.Message(arbitration_id=VESC_CAN_ID, data=data, is_extended_id=False)
    bus.send(msg)

def ramp_motor(target_duty: float, steps=20, delay=0.1):
    print(f"🔼 Ramping motor to duty {target_duty}")
    for i in range(1, steps + 1):
        duty = target_duty * i / steps
        send_duty(duty)
        time.sleep(delay)
    print(f"⏸ Holding duty {target_duty} for 2s")
    time.sleep(2)
    print("🔻 Ramping down to 0.0")
    for i in range(steps, -1, -1):
        duty = target_duty * i / steps
        send_duty(duty)
        time.sleep(delay)
    send_duty(0.0)
    print("🔴 Motor stopped")

# ---- Main ----
if __name__ == "__main__":
    print("✅ CAN interface ready")
    ramp_motor(0.5)
