import serial
import time
from pyvesc import decode
import logging

SERIAL_PORT = "/dev/ttyACM1"
BAUD_RATE = 115200
TIMEOUT = 1.0

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Try sending a possible packet — you may need to adjust the command ID
GET_VALUES_PACKET = b"\x02\x04\x00\x03\x00\x00"  # placeholder – may need update

def open_serial():
    try:
        sp = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT)
        logging.info("Opened serial port %s", SERIAL_PORT)
        return sp
    except Exception as e:
        logging.error("Failed to open serial port: %s", e)
        raise

def raw_read_test(sp):
    logging.info("Sending request packet: %s", GET_VALUES_PACKET)
    sp.write(GET_VALUES_PACKET)
    time.sleep(0.1)
    buff = sp.read(1024)
    logging.info("Received %d bytes: %s", len(buff), buff.hex())
    msg, consumed = decode(buff)
    logging.info("Decoded message: %s (consumed %d bytes)", msg, consumed)

if __name__ == "__main__":
    sp = open_serial()
    try:
        raw_read_test(sp)
    finally:
        sp.close()
        logging.info("Serial port closed.")
