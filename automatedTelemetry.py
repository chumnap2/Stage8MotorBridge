# automatedTelemetry.py
import socket
import json
import time
import csv
from datetime import datetime

HOST = "127.0.0.1"
PORT = 5555
CSV_FILE = "motor_telemetry_live.csv"

def send(sock, cmd):
    sock.sendall(cmd.encode() + b'\n')

def readline(sockfile):
    line = sockfile.readline()
    if not line:
        return None
    return line.decode().strip()

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((HOST, PORT))
        sockfile = sock.makefile('rb')  # buffered readlines
        print("✅ Connected to MotorBridgeServer")

        # open CSV
        with open(CSV_FILE, 'w', newline='') as csvf:
            fieldnames = ['timestamp','duty','rpm','current','raw']
            writer = csv.DictWriter(csvf, fieldnames=fieldnames)
            writer.writeheader()

            # Enable motor safely
            send(sock, "enable")
            time.sleep(0.3)
            # optionally confirm ACK
            try:
                resp = readline(sockfile)
                print("Server:", resp)
            except Exception:
                pass

            # Ramp example with telemetry collection
            for duty in [i * 0.1 for i in range(6)]:  # 0.0 .. 0.5
                cmd = f"duty {duty:.2f}"
                print("Sending:", cmd)
                send(sock, cmd)

                # collect telemetry for 1 second
                end = time.time() + 1.0
                while time.time() < end:
                    line = readline(sockfile)
                    if line is None:
                        print("Connection closed by server")
                        return
                    # server sends JSON telemetry lines; sometimes sends ACK/ERR too
                    try:
                        # allow both JSON and plain tokens
                        if line.startswith("{"):
                            t = json.loads(line)
                            ts = datetime.now().isoformat()
                            writer.writerow({
                                'timestamp': ts,
                                'duty': t.get('duty'),
                                'rpm': t.get('rpm'),
                                'current': t.get('current'),
                                'raw': line
                            })
                            print("Telemetry:", t)
                        else:
                            print("Server:", line)
                    except json.JSONDecodeError:
                        print("Non-JSON:", line)

            # final stop
            send(sock, "stop")
            # read any final lines for a short time
            t_end = time.time() + 0.5
            while time.time() < t_end:
                line = readline(sockfile)
                if not line:
                    break
                print("Server:", line)

        print("✅ Telemetry logged to", CSV_FILE)

if __name__ == "__main__":
    main()
