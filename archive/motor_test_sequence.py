import asyncio

SERVER_HOST = "127.0.0.1"
SERVER_PORT = 9001

async def send_command(writer, cmd):
    writer.write((cmd + "\n").encode())
    await writer.drain()
    print(f"> {cmd}")

async def handle_telemetry(reader):
    while True:
        line = await reader.readline()
        if not line:
            print("\n[Disconnected from server]")
            break
        decoded = line.decode().strip()
        if decoded.startswith("T:"):
            pos, vel = decoded[2:].split(",")
            print(f"\r📡 Telemetry -> Position: {pos}, Velocity: {vel}", end="")
        else:
            print(f"\n[Server] {decoded}")

async def motor_sequence():
    reader, writer = await asyncio.open_connection(SERVER_HOST, SERVER_PORT)
    print(f"Connected to {SERVER_HOST}:{SERVER_PORT}")

    # Start telemetry reader
    asyncio.create_task(handle_telemetry(reader))

    # Step 1: Enable motor
    await send_command(writer, "enable")
    await asyncio.sleep(1)

    # Step 2: Ramp speed
    for speed in range(1, 6):  # 1 → 5
        await send_command(writer, f"set_speed {speed}")
        await asyncio.sleep(1)

    # Step 3: Hold speed
    print("\n⏱ Holding speed 5 for 5 seconds...")
    await asyncio.sleep(5)

    # Step 4: Change speed dynamically
    await send_command(writer, "set_speed 3")
    await asyncio.sleep(3)
    await send_command(writer, "set_speed 1")
    await asyncio.sleep(2)

    # Step 5: Stop motor
    await send_command(writer, "set_speed 0")
    await asyncio.sleep(1)
    await send_command(writer, "disable")
    print("\n✅ Motor sequence complete.")

    writer.close()
    await writer.wait_closed()

if __name__ == "__main__":
    asyncio.run(motor_sequence())
