#!/usr/bin/env python3
"""
motor_client_live.py — Stage9 MotorBridge client with live telemetry
"""

import socket
import threading
import time

HOST = "127.0.0.1"
PORT = 12345  # Match Stage9 TCP server port

# Shared flag to stop threads
running = True

def receive_telemetry(sock):
    """Thread to receive telemetry lines from the server"""
    while running:
        try:
            line = sock.recv(1024)  # read up to 1024 bytes
            if not line:
                print("[INFO] Server closed connection.")
                break
            print("[TELEMETRY]", line.decode().strip())
        except Exception as e:
            print("[ERROR] Telemetry receive:", e)
            break

def main():
    global running
    with socket.create_connection((HOST, PORT)) as sock:
        print(f"✅ Connected to Stage9 MotorBridgeServer at {HOST}:{PORT}")

        # Start telemetry thread
        telemetry_thread = threading.Thread(target=receive_telemetry, args=(sock,), daemon=True)
        telemetry_thread.start()

        print("Commands:")
        print("  enable           -> Enable motor")
        print("  disable          -> Disable motor")
        print("  duty 0.0-0.4     -> Set duty (medium motor safe max 0.4)")
        print("  stop             -> Disable motor and exit")

        try:
            while True:
                cmd = input("> ").strip().lower()
                if not cmd:
                    continue

                if cmd == "stop":
                    sock.sendall(b"DISABLE\n")
                    print("[INFO] Stopping client.")
                    break
                elif cmd.startswith("duty"):
                    # Extract duty value
                    parts = cmd.split()
                    if len(parts) == 2:
                        try:
                            val = float(parts[1])
                            if val < 0 or val > 0.4:
                                print("[WARN] Duty out of safe range 0.0-0.4")
                                continue
                            sock.sendall(f"SET_DUTY:{val}\n".encode())
                        except ValueError:
                            print("[WARN] Invalid duty value")
                    else:
                        print("[WARN] Usage: duty 0.3")
                elif cmd == "enable":
                    sock.sendall(b"ENABLE\n")
                elif cmd == "disable":
                    sock.sendall(b"DISABLE\n")
                else:
                    print("[WARN] Unknown command:", cmd)

        except KeyboardInterrupt:
            print("\n[INFO] Ctrl+C pressed, exiting client.")
        finally:
            running = False
            time.sleep(0.1)  # allow telemetry thread to finish

if __name__ == "__main__":
    main()
