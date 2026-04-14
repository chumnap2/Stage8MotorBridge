# telemetry_reader_autoreconnect_safe.py
import serial
import time
import logging
from pyvesc import encode, decode, GetValues

SERIAL_PORT = "/dev/ttyACM1"
BAUD_RATE = 115200
TIMEOUT = 0.1  # seconds
RECONNECT_DELAY = 2.0  # seconds between retries

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

def open_serial():
    """Attempt to open the serial port."""
    while True:
        try:
            sp = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT)
            logging.info(f"Serial port {SERIAL_PORT} opened successfully.")
            return sp
        except serial.SerialException as e:
            logging.warning(f"Failed to open serial port: {e}. Retrying in {RECONNECT_DELAY}s...")
            time.sleep(RECONNECT_DELAY)

def get_vesc_values(sp):
    """Request telemetry from VESC and return decoded message."""
    msg = GetValues()
    sp.write(encode(msg))

    buff = b""
    start_time = time.time()
    while True:
        buff += sp.read(1024)
        decoded, consumed = decode(buff)
        if decoded:
            return decoded
        if consumed > 0:
            buff = buff[consumed:]
        if time.time() - start_time > 2.0:
            raise TimeoutError("No response from VESC")

def main():
    sp = open_serial()
    try:
        while True:
            try:
                values = get_vesc_values(sp)
                # Print all fields for inspection
                print(values)
                # Example: RPM, motor current, voltage input
                # print(values.rpm, values.current_motor, values.voltage_input)
                time.sleep(1.0)
            except TimeoutError as e:
                logging.warning(f"Telemetry error: {e}. Reconnecting...")
                sp.close()
                time.sleep(RECONNECT_DELAY)
                sp = open_serial()
    except KeyboardInterrupt:
        sp.close()
        logging.info("Serial port closed.")

if __name__ == "__main__":
    main()
