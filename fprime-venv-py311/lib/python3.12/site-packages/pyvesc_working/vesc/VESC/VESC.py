#!/usr/bin/env python3
import threading
import time
from serial import Serial

# --- Minimal VESC protocol constants ---
COMM_SET_DUTY = 5
COMM_GET_VALUES = 4

START_BYTE = b'\x02'
END_BYTE = b'\x03'


def float_to_bytes(f):
    """Convert float32 to 4 bytes, big-endian."""
    import struct
    return struct.pack('>f', f)


def encode_packet(payload_bytes):
    """Encode VESC packet with start, length, payload, CRC, end."""
    length = len(payload_bytes)
    length_byte = bytes([length])
    crc = sum(payload_bytes) & 0xFF
    return START_BYTE + length_byte + payload_bytes + bytes([crc]) + END_BYTE


class VESC:
    def __init__(self, port="/dev/ttyACM0", baudrate=115200):
        self.ser = Serial(port, baudrate=baudrate, timeout=0.1)
        self._lock = threading.Lock()
        self.firmware_version = (0, 0, 0)  # optional

    def _send_payload(self, payload_bytes):
        packet = encode_packet(payload_bytes)
        with self._lock:
            self.ser.write(packet)

    def set_duty_cycle(self, duty: float):
        """Send a duty cycle (-1.0..1.0) to VESC."""
        duty_bytes = float_to_bytes(duty)
        payload = bytes([COMM_SET_DUTY]) + duty_bytes
        self._send_payload(payload)

    def get_values(self):
        """Request telemetry (dummy implementation, can be extended)."""
        payload = bytes([COMM_GET_VALUES])
        self._send_payload(payload)
        time.sleep(0.05)
        with self._lock:
            return self.ser.read(1024)

    def stop(self):
        self.set_duty_cycle(0.0)
