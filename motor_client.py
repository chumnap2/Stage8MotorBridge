import socket

HOST = "127.0.0.1"
#PORT = 5555
PORT = 12345
def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))
    print("✅ Connected to MotorBridgeServer")
    print("Commands:")
    print("  enable")
    print("  duty 0.3   (0.0 to 1.0)")
    print("  stop")

    while True:
        try:
            cmd = input("> ").strip()

            if not cmd:
                continue

            # normalise user mistakes
            cmd = cmd.replace("o.", "0.").replace("O.", "0.")

            sock.sendall(cmd.encode() + b'\n')

        except KeyboardInterrupt:
            print("\nExiting client.")
            break

    sock.close()

if __name__ == "__main__":
    main()
