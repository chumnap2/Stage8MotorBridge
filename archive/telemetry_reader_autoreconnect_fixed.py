import time
import logging
from serial import Serial
from pyvesc.VESC.VESC import VESC
from pyvesc.VESC.messages import GetValues

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

import glob
ports = glob.glob("/dev/ttyACM*")
SERIAL_PORT = ports[0] if ports else "/dev/ttyACM0"

BAUDRATE = 115200
RECONNECT_DELAY = 2  # seconds
SPIN_DURATION = 4    # seconds

def open_vesc():
    while True:
        try:
            vesc = VESC(serial_port=SERIAL_PORT, baudrate=BAUDRATE, timeout=0.5)
            logger.info("Serial port opened successfully.")
            return vesc
        except Exception as e:
            logger.error(f"Error opening serial port: {e}")
            logger.info(f"Reconnect in {RECONNECT_DELAY}s...")
            time.sleep(RECONNECT_DELAY)

def safe_spin_ramp(vesc: VESC):
    try:
        logger.info("Starting safe motor spin ramp...")
        vesc.set_duty_cycle(0.2)  # ramp to low duty cycle
        time.sleep(SPIN_DURATION)
        logger.info("Spin complete. Stopping motor...")
        vesc.set_duty_cycle(0.0)
    except Exception as e:
        logger.warning(f"Telemetry read error: {e}")

def main():
    while True:
        vesc = open_vesc()
        safe_spin_ramp(vesc)
        vesc.serial_port.close()
        time.sleep(RECONNECT_DELAY)

if __name__ == "__main__":
    main()
