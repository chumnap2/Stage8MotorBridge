#!/usr/bin/env python3
import socket
import threading
import time

# Use YOUR local patched pyvesc_working version
from pyvesc_working.pyvesc.VESC import VESC

HOST = "127.0.0.1"
PORT = 5005


def handle_client(conn, addr, vesc):
    print(f"🤝 Julia client connected: {addr}")

    with conn:
        buf = ""
        while True:
            try:
                chunk = conn.recv(64).decode("utf-8")
                if not chunk:
                    print("❌ Julia client disconnected")
                    break

                buf += chunk
                # Parse per line
                while "\n" in buf:
                    line, buf = buf.split("\n", 1)
                    line = line.strip()

                    if not line:
                        continue

                    # Expect: "duty 0.5"
                    if line.startswith("duty"):
                        try:
                            _, val = line.split()
                            duty = float(val)
                            print(f"➡️ Setting duty: {duty}")
                            vesc.set_duty_cycle(duty)
                        except Exception as e:
                            print(f"⚠️ Invalid duty command '{line}': {e}")

            except Exception as e:
                print(f"⚠️ Client error: {e}")
                break


def main():
    print("🔌 Connecting to VESC at /dev/ttyACM0 ...")

    # This matches the constructor in your installed version
    vesc = VESC("/dev/ttyACM0")

    print("🟢 Connected to VESC")
    print(f"🟢 VESC server running at {HOST}:{PORT}")

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((HOST, PORT))
    server.listen(1)

    try:
        while True:
            conn, addr = server.accept()
            thread = threading.Thread(
                target=handle_client,
                args=(conn, addr, vesc),
                daemon=True
            )
            thread.start()

    except KeyboardInterrupt:
        print("\n🛑 Shutting down server...")
        vesc.set_duty_cycle(0.0)
        print("🔴 Motor stopped.")
        server.close()


if __name__ == "__main__":
    main()
