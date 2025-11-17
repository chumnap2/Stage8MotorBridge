import asyncio

SERVER_HOST = "127.0.0.1"
SERVER_PORT = 9001

async def handle_server(reader):
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

async def handle_user(writer):
    loop = asyncio.get_running_loop()
    while True:
        cmd = await loop.run_in_executor(None, input, "\n> ")
        if cmd.lower() in ("quit", "exit"):
            print("Exiting client...")
            writer.close()
            await writer.wait_closed()
            break
        writer.write((cmd + "\n").encode())
        await writer.drain()

async def main():
    try:
        reader, writer = await asyncio.open_connection(SERVER_HOST, SERVER_PORT)
        print(f"Connected to {SERVER_HOST}:{SERVER_PORT}")

        server_task = asyncio.create_task(handle_server(reader))
        user_task = asyncio.create_task(handle_user(writer))

        await asyncio.wait([server_task, user_task], return_when=asyncio.FIRST_COMPLETED)
        server_task.cancel()
        user_task.cancel()

    except ConnectionRefusedError:
        print(f"Cannot connect to {SERVER_HOST}:{SERVER_PORT}")
    except Exception as e:
        print(f"[Client error] {e}")

if __name__ == "__main__":
    asyncio.run(main())
