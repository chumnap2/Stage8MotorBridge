#!/usr/bin/env python3
import time
from vescminimal_nov20 import VESC

vesc = VESC("/dev/ttyACM1")

for duty in [0.05, 0.1, 0.2]:
    print(f"➡️ Setting duty = {duty}")
    pkt = vesc.set_duty_cycle(duty)
    print("📦 Sent packet:", pkt.hex())
    time.sleep(2)

print("🔴 Stop")
vesc.set_duty_cycle(0.0)
