import socket
import time
import csv

HOST = "127.0.0.1"
PORT = 5555
DUTY_STEPS = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]
TELEMETRY_FILENAME = "motor_telemetry_log.csv"
TELEMETRY_WAIT = 0.1  # seconds between steps / telemetry read

def send_command(sock, cmd):
    sock.sendall(cmd.encode() + b"\n")
    data = sock.recv(1024).decode().strip()
    return data

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))
    print("✅ Connected to MotorBridgeServer")

    telemetry_log = []

    # Enable motor
    resp = send_command(sock, "enable")
    print("Motor enabled (armed)", resp)

    # Ramp duty
    for duty in DUTY_STEPS:
        cmd = f"duty {duty:.2f}"
        resp = send_command(sock, cmd)
        print(f"Sent command: {cmd}")
        # Read telemetry after sending
        try:
            telemetry_raw = sock.recv(1024).decode().strip()
        except Exception:
            telemetry_raw = None
        print("Telemetry:", telemetry_raw)
        telemetry_log.append({"command": cmd, "telemetry": telemetry_raw})
        time.sleep(TELEMETRY_WAIT)

    # Stop motor safely
    resp = send_command(sock, "stop")
    print("Motor stopped safely", resp)

    # Save telemetry to CSV
    with open(TELEMETRY_FILENAME, "w", newline="") as csvfile:
        fieldnames = ["command", "telemetry"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for row in telemetry_log:
            writer.writerow(row)

    print(f"✅ Telemetry logged to {TELEMETRY_FILENAME}")
    sock.close()

if __name__ == "__main__":
    main()
