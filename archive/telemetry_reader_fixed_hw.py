#!/usr/bin/env python3
import time
import serial.tools.list_ports
from pyvesc.VESC.VESC import VESC

def find_vesc_port():
    """Automatically find the VESC serial port"""
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if 'ACM' in p.device or 'USB' in p.device:
            return p.device
    raise RuntimeError("No VESC port found!")

def main():
    port = find_vesc_port()
    print(f"Found VESC port: {port}")
    vesc = VESC(port)
    print(f"Connected to VESC on {port}")

    try:
        while True:
            try:
                values = vesc.get_measurements()
                # Use fields available in your version of pyvesc
                print(f"RPM: {values.rpm}, Duty: {values.duty_cycle}, Current: {values.current_motor}")
                time.sleep(0.5)
            except Exception as e:
                print(f"[ERROR] Communication error: {e}")
                print("[INFO] Reconnecting in 2s...")
                time.sleep(2)
                port = find_vesc_port()
                vesc = VESC(port)
    except KeyboardInterrupt:
        print("Exiting...")
        # Stop motor safely if needed
        try:
            vesc.set_duty_cycle(0)
        except:
            pass

if __name__ == "__main__":
    main()
