#!/usr/bin/env python3
import struct
import serial
import time

COMM_SET_DUTY = 0x00  # VESC command

def crc16(data):
    crc = 0
    for b in data:
        crc ^= (b << 8)
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ 0x1021
            else:
                crc <<= 1
            crc &= 0xFFFF
    return crc

class SimpleVESC:
    def __init__(self, port="/dev/ttyACM0", baud=115200):
        self.ser = serial.Serial(port, baudrate=baud, timeout=0.01)
    
    def set_duty_cycle(self, duty: float):
        # Payload = COMM_SET_DUTY + float32
        payload = bytes([COMM_SET_DUTY]) + struct.pack(">f", float(duty))
        length = len(payload)
        header = bytes([2, length])  # 2 = short frame
        crc = crc16(payload)
        crc_bytes = struct.pack(">H", crc)
        packet = header + payload + crc_bytes + bytes([3])
        self.ser.write(packet)
        self.ser.flush()
