import serial, time, struct

def crc16(data: bytes) -> int:
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

def make_packet(cmd):
    payload = bytes([cmd])
    crc = crc16(payload)
    return bytes([2, len(payload)]) + payload + struct.pack(">H", crc) + bytes([3])

with serial.Serial("/dev/ttyUSB0", 115200, timeout=1) as sp:
    packet = make_packet(4)  # COMM_GET_VALUES
    print(f"Sending packet: {packet.hex()}")
    sp.write(packet)
    time.sleep(0.1)
    reply = sp.read(256)
    print("Reply:", reply.hex())
