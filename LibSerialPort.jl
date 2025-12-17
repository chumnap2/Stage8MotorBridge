using LibSerialPort, Sockets, Dates, CRC

# ------------------------------
# CONFIG
# ------------------------------
const SERIAL_PORT = "/dev/ttyACM0"
const BAUDRATE = 115200

# Conservative limits
const MAX_DUTY = 0.05       # 5%
const MAX_CURRENT = 0.5     # 0.5 A

# Ramping
const RAMP_INTERVAL = 0.05      # seconds
const TARGET_RAMP_TIME = 3.0    # seconds to reach max
const RAMP_STEP_DUTY = MAX_DUTY * RAMP_INTERVAL / TARGET_RAMP_TIME
const RAMP_STEP_CURRENT = MAX_CURRENT * RAMP_INTERVAL / TARGET_RAMP_TIME

# ------------------------------
# OPEN VESC SERIAL
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
# Packet protocol constants
const COMM_SET_DUTY = 0x01
const COMM_SET_CURRENT = 0x02

function vesc_packet(command::UInt8, value::Float32)
    # Value in float -> 4 bytes little-endian
    bytes = reinterpret(UInt8, [value])
    payload = UInt8[command; bytes...]  # command + value bytes
    crc_val = CRC.crc16xmodem(payload)
    crc_bytes = UInt8[(crc_val >> 8) & 0xFF, crc_val & 0xFF]
    # Packet framing
    return UInt8[0x02; payload; crc_bytes; 0x03]  # 0x02=start, 0x03=end
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
        current_duty = clamp(current_duty + sign(target_duty - current_duty)*RAMP_STEP_DUTY,
                             min(current_duty,target_duty),
                             max(current_duty,target_duty))
        send_vesc_packet(COMM_SET_DUTY, Float32(current_duty))

        # Ramp current
        current_current = clamp(current_current + sign(target_current - current_current)*RAMP_STEP_CURRENT,
                                min(current_current,target_current),
                                max(current_current,target_current))
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
