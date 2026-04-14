from pyvesc_working.pyvesc import VESC

PORT = "/dev/ttyACM0"

try:
    print(f"🔌 Connecting to VESC on {PORT} ...")
    vesc = VESC(PORT, start_heartbeat=False)  # don’t start heartbeat yet
    fw = vesc.get_firmware_version()
    print(f"✅ Firmware version: {fw}")
except Exception as e:
    print(f"❌ Failed to connect: {e}")
