import asyncio

HOST = "127.0.0.1"
PORT = 9001

async def send(writer, cmd):
    writer.write((cmd + "\n").encode())
    await writer.drain()

async def test_motor():
    reader, writer = await asyncio.open_connection(HOST, PORT)
    print("✅ Connected to MotorBridgeServer")

    # Enable motor
    await send(writer, "enable")

    # Set to minimum duty
    min_duty = 0.5
    print(f"➡️ Spinning motor at minimum duty: {min_duty}")
    await send(writer, f"set_speed {min_duty}")

    # Hold for 5 seconds
    await asyncio.sleep(5)

    # Stop motor
    await send(writer, "disable")
    print("🔴 Motor stopped")

    writer.close()
    await writer.wait_closed()

if __name__ == "__main__":
    asyncio.run(test_motor())
