using LibSerialPort, Sockets, Dates

# ------------------------------
# CONFIG
# ------------------------------
const SERIAL_PORT = "/dev/ttyACM0"
const BAUDRATE = 115200

# Conservative limits for small BLDC
const MAX_DUTY = 0.2       # 20% duty, enough to start spinning
const MAX_CURRENT = 0.5     # 0.5 A

# Ramping
const RAMP_INTERVAL = 0.05       # seconds per step
const TARGET_RAMP_TIME = 3.0     # seconds to reach target
const RAMP_STEP_DUTY = MAX_DUTY * RAMP_INTERVAL / TARGET_RAMP_TIME
const RAMP_STEP_CURRENT = MAX_CURRENT * RAMP_INTERVAL / TARGET_RAMP_TIME

# ------------------------------
# OPEN SERIAL
# ------------------------------
sp = LibSerialPort.open(SERIAL_PORT, BAUDRATE)
println("Serial port opened: $SERIAL_PORT at $BAUDRATE bps")

# ------------------------------
# STATE
# ------------------------------
current_duty = 0.0
target_duty = 0.0
current_current = 0.0
target_current = 0.0

# ------------------------------
# VESC PACKET COMMANDS
# ------------------------------
# Packet format constants
const COMM_SET_DUTY = 0x01
const COMM_SET_CURRENT = 0x02

# Simple CRC16-XMODEM
function crc16_xmodem(data::Vector{UInt8})
    crc = 0x0000
    for b in data
        crc = crc ⊻ (b << 8)
        for i in 1:8
            if crc & 0x8000 != 0
                crc = (crc << 1) ⊻ 0x1021
            else
                crc <<= 1
            end
            crc &= 0xFFFF
        end
    end
    return crc
end

# Create VESC packet
function vesc_packet(command::UInt8, value::Float32)
    payload = [command; reinterpret(UInt8, [value])]  # command + 4-byte float
    crc_val = crc16_xmodem(payload)
    crc_bytes = UInt8[(crc_val >> 8) & 0xFF, crc_val & 0xFF]
    return UInt8[0x02; payload; crc_bytes; 0x03]  # STX + payload + CRC + ETX
end

function send_vesc_packet(command::UInt8, value::Float32)
    packet = vesc_packet(command, value)
    LibSerialPort.write(sp, packet)
end

# ------------------------------
# RAMP LOOP
# ------------------------------
@async begin
    while true
        # Ramp duty
        delta_duty = clamp(target_duty - current_duty, -RAMP_STEP_DUTY, RAMP_STEP_DUTY)
        current_duty += delta_duty
        send_vesc_packet(COMM_SET_DUTY, Float32(current_duty))

        # Ramp current
        delta_current = clamp(target_current - current_current, -RAMP_STEP_CURRENT, RAMP_STEP_CURRENT)
        current_current += delta_current
        send_vesc_packet(COMM_SET_CURRENT, Float32(current_current))

        sleep(RAMP_INTERVAL)
    end
end

# ------------------------------
# TCP SERVER
# ------------------------------
server = Sockets.listen(12345)
println("MotorBridge TCP server running on 127.0.0.1:12345")

while true
    client = accept(server)
    println("Client connected: ", client)

    @async begin
        while !eof(client)
            line = readline(client) |> strip

            if startswith(line, "SET DUTY")
                value = parse(Float64, split(line)[3])
                target_duty = clamp(value, -MAX_DUTY, MAX_DUTY)

            elseif startswith(line, "SET CURRENT")
                value = parse(Float64, split(line)[3])
                target_current = clamp(value, -MAX_CURRENT, MAX_CURRENT)

            elseif line == "STOP"
                target_duty = 0.0
                target_current = 0.0
            end
        end

        close(client)
        println("Client disconnected")
    end
end
