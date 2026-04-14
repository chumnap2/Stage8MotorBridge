import serial
import time
import logging
from pyvesc import GetValues, encode, decode

SERIAL_PORT = "/dev/ttyACM1"
BAUD_RATE = 115200
TIMEOUT = 0.5  # seconds
RECONNECT_DELAY = 2.0  # seconds

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Only include fields that exist in firmware 6.06
SAFE_FIELDS_6_06 = [
    "rpm", "current_motor", "current_in", "duty_cycle",
    "temp_motor", "temp_input", "voltage_input", "amp_hours",
    "amp_hours_charged", "tachometer", "tachometer_abs",
    "fault_code", "pid_pos", "controller_id", "avg_id", "timing"
]

def connect_serial():
    """Connect to the VESC serial port, retry until successful."""
    while True:
        try:
            sp = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT)
            logging.info(f"Serial port {SERIAL_PORT} opened successfully.")
            return sp
        except Exception as e:
            logging.warning(f"Failed to open serial port: {e}")
            logging.info(f"Retrying in {RECONNECT_DELAY} seconds...")
            time.sleep(RECONNECT_DELAY)

def safe_decode(raw_bytes):
    """Decode VESC telemetry safely, ignoring missing fields."""
    try:
        msg, _ = decode(raw_bytes)
        if msg is None:
            return None
        safe_data = {field: getattr(msg, field) for field in SAFE_FIELDS_6_06 if hasattr(msg, field)}
        return safe_data if safe_data else None
    except AttributeError:
        # Occurs when firmware doesn't provide some fields
        return None
    except Exception as e:
        logging.warning(f"Decoding failed: {e}")
        return None

def get_vesc_values(sp):
    """Request and read VESC telemetry safely."""
    try:
        sp.write(encode(GetValues()))
        time.sleep(0.05)  # short delay to allow VESC to respond
        raw_bytes = sp.read(1024)
        if not raw_bytes:
            return None
        return safe_decode(raw_bytes)
    except Exception as e:
        logging.warning(f"Serial communication failed: {e}")
        return None

def main():
    sp = connect_serial()
    while True:
        values = get_vesc_values(sp)
        if values:
            logging.info(values)

        if values is None:
            logging.warning("No data received. Attempting to reconnect...")
            try:
                sp.close()
            except Exception:
                pass
            sp = connect_serial()

        time.sleep(0.05)  # avoid CPU hogging

if __name__ == "__main__":
    main()
