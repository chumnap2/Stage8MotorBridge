import serial
import struct

COMM_SET_DUTY = 5

def crc16(data):
    crc = 0
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ 0x1021
            else:
                crc <<= 1
            crc &= 0xFFFF
    return crc

class VESC:
    def __init__(self, port, baudrate=115200):
        self.ser = serial.Serial(port, baudrate=baudrate, timeout=0.1)
    
    def send_packet(self, cmd, payload):
        payload = bytes([cmd]) + payload
        length = len(payload)

        if length < 256:
            start = bytes([2])       # short packet
            length_bytes = bytes([length])
        else:
            raise ValueError("Packet too long")

        crc_value = crc16(payload)
        crc_bytes = struct.pack(">H", crc_value)
        end = bytes([3])

        packet = start + length_bytes + payload + crc_bytes + end
        self.ser.write(packet)
        return packet

    def set_duty_cycle(self, duty):
        duty = max(min(duty, 1.0), -1.0)
        payload = struct.pack(">f", duty)
        return self.send_packet(COMM_SET_DUTY, payload)
