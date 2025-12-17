using LibSerialPort, Sockets, Dates

# ------------------------------
# CONFIG
# ------------------------------
const SERIAL_PORT = "/dev/ttyACM0"
const BAUDRATE = 115200

# Conservative limits
const MAX_DUTY = 0.05       # 5%
const MAX_CURRENT = 0.5     # 0.5 A

# Ramping config
const RAMP_INTERVAL = 0.05      # seconds between ramp steps
const TARGET_RAMP_TIME = 3.0    # seconds to go from 0 -> max
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
# HELPERS
# ------------------------------
function send_vesc_command(cmd::String)
    LibSerialPort.write(sp, cmd * "\n")
end

function read_vesc_telemetry()
    n = LibSerialPort.bytes_available(sp)
    if n > 0
        line = String(take!(sp, n))
        return chomp(line)
    end
    return ""
end

function ramp_to!(current::Float64, target::Float64, step::Float64)
    if current < target
        return min(current + step, target)
    elseif current > target
        return max(current - step, target)
    else
        return current
    end
end

# ------------------------------
# ASYNC RAMP LOOP
# ------------------------------
@async begin
    while true
        current_duty = ramp_to!(current_duty, target_duty, RAMP_STEP_DUTY)
        send_vesc_command("duty $current_duty")

        current_current = ramp_to!(current_current, target_current, RAMP_STEP_CURRENT)
        send_vesc_command("current $current_current")

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

            # ----- PARSE COMMANDS -----
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

            # ----- SEND TELEMETRY BACK -----
            telemetry = read_vesc_telemetry()
            telemetry_msg = telemetry != "" ? telemetry : "RPM=0 CURRENT=0.0 VOLTAGE=0.0"
            write(client, telemetry_msg * "\n")
        end

        close(client)
        println("Client disconnected")
    end
end
