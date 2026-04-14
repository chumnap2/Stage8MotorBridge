
#!/usr/bin/env python3
import time
from pyvesc_working.pyvesc.VESC import VESC
from pyvesc_working.pyvesc.VESC.messages import SetDutyCycle

def main():
    print("🔌 Connecting to VESC at /dev/ttyACM1 ...")
    vesc = VESC("/dev/ttyACM1")

    print("🟢 Connected to VESC")

    for duty in [0.1, 0.2, 0.3]:
        print(f"➡️ Building packet for duty = {duty}")
        msg = SetDutyCycle(duty)
        pkt = msg.serialize()

        print(f"📦 Packet bytes: {pkt.hex()}")

        print("📤 Sending packet...")
        vesc.ser.write(pkt)
        time.sleep(2)

    print("🔴 Stopping")
    stop = SetDutyCycle(0.0)
    vesc.ser.write(stop.serialize())

if __name__ == "__main__":
    main()
