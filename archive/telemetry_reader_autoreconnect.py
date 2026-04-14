import serial
import time
from pyvesc import decode
import logging

SERIAL_PORT = "/dev/ttyACM1"
BAUD_RATE = 115200
TIMEOUT = 0.1
TELEMETRY_INTERVAL = 1.0
RECONNECT_DELAY = 2.0

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Pre-encoded "GetValues" request packet
GET_VALUES_PACKET = b"\x02\x04\x00\x03\x00\x00"  # works for most VESC firmware

def open_serial():
    """Open serial port with retry loop."""
    while True:
        try:
            sp = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT)
            logging.info("Serial port %s opened successfully.", SERIAL_PORT)
            return sp
        except Exception as e:
            logging.warning("Failed to open serial port: %s. Retrying in %.1f s...", e, RECONNECT_DELAY)
            time.sleep(RECONNECT_DELAY)

def get_vesc_values(sp):
    """Send raw telemetry request and decode the reply."""
    try:
        sp.write(GET_VALUES_PACKET)
    except serial.SerialException as e:
        raise ConnectionError(f"Failed to write to serial port: {e}")

    buff = b""
    start_time = time.time()
    while True:
        try:
            buff += sp.read(1024)
        except serial.SerialException as e:
            raise ConnectionError(f"Serial read failed: {e}")

        msg, consumed = decode(buff)
        if msg:
            return msg
        if time.time() - start_time > 2.0:
            raise TimeoutError("No response from VESC")
        if consumed > 0:
            buff = buff[consumed:]

def main():
    sp = open_serial()
    while True:
        try:
            values = get_vesc_values(sp)
            # Print all fields dynamically
            for k, v in vars(values).items():
                print(f"{k}: {v}", end=" | ")
            print()
            time.sleep(TELEMETRY_INTERVAL)

        except (TimeoutError, ConnectionError) as e:
            logging.warning("Telemetry error: %s. Reconnecting...", e)
            try:
                sp.close()
            except Exception:
                pass
            time.sleep(RECONNECT_DELAY)
            sp = open_serial()

        except KeyboardInterrupt:
            logging.info("KeyboardInterrupt detected. Closing serial port.")
            try:
                sp.close()
            except Exception:
                pass
            break

if __name__ == "__main__":
    main()
