from pyvesc_working.pyvesc.VESC import VESC
import time

# Connect to VESC
vesc = VESC("/dev/ttyACM1")
print("✅ Connected to VESC")

try:
    print("➡️ Spinning motor at 0.5 duty for 3s")
    vesc.set_duty_cycle(0.5)
    time.sleep(3)
finally:
    print("🔴 Stopping motor")
    vesc.set_duty_cycle(0.0)
