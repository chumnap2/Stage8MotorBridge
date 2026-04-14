import asyncio
import sys

HOST = "127.0.0.1"
PORT = 9001


# ---------------------------------------------
# Telemetry listener
# ---------------------------------------------
async def telemetry_reader(reader):
    try:
        while True:
            line = await reader.readline()
            if not line:
                print("\n🔌 Server disconnected.")
                sys.exit(0)

            msg = line.decode().strip()

            if msg.startswith("T:"):
                try:
                    _, data = msg.split(":")
                    pos, vel = data.split(",")
                    print(f"📡 Telemetry -> Position: {pos}, Velocity: {vel}")
                except:
                    print(f"⚠️ Bad telemetry: {msg}")
            else:
                print(f"[Server] {msg}")

    except asyncio.CancelledError:
        return


# ---------------------------------------------
# Send a command (helper)
# ---------------------------------------------
async def send(writer, cmd):
    writer.write((cmd + "\n").encode())
    await writer.drain()


# ---------------------------------------------
# Main interactive client
# ---------------------------------------------
async def motor_client():
    print(f"Connecting to {HOST}:{PORT} ...")

    reader, writer = await asyncio.open_connection(HOST, PORT)
    print("✅ Connected!")

    # Start telemetry listener
    asyncio.create_task(telemetry_reader(reader))

    print("\nType commands:")
    print("  enable")
    print("  disable")
    print("  set_speed <value>")
    print("  exit\n")

    # Input loop
    while True:
        try:
            cmd = input("> ").strip()

            if cmd == "":
                continue

            if cmd == "exit":
                print("🔌 Closing connection.")
                writer.close()
                await writer.wait_closed()
                sys.exit(0)

            await send(writer, cmd)

        except (KeyboardInterrupt, EOFError):
            print("\n🔌 Exiting.")
            writer.close()
            await writer.wait_closed()
            sys.exit(0)


# Run client
if __name__ == "__main__":
    asyncio.run(motor_client())
