#!/usr/bin/env julia
# MotorBridgeServer.jl — PyCall + pyserial + TCP server

using Sockets
using Dates
using PyCall

println("✅ Loading pyvesc + serial...")

# ---- PYTHON MODULES ----
serial = pyimport("serial")
pyvesc = pyimport("pyvesc")
SetDutyCycle = pyvesc.SetDutyCycle
encode = pyvesc.encode

# ---- CONFIG ----
const SERIAL_PORT = "/dev/ttyACM1"
const BAUD_RATE = 115200
const HOST = "127.0.0.1"
const PORT = 5555

# ---- GLOBAL STATE ----
global motor_enabled = false
global port = nothing

# ---- CONNECT TO VESC ----
try
    global port
    port = serial.Serial(SERIAL_PORT, BAUD_RATE)
    println("✅ VESC connected on $SERIAL_PORT")
catch e
    println("❌ Failed to open serial port: ", e)
    exit(1)
end

# ---- TCP SERVER ----
#server = listen(IPAddr(HOST), PORT)
server = listen(PORT)
println("✅ TCP MotorBridgeServer listening on $HOST:$PORT")

function log(msg)
    println("$(Dates.now()) $msg")
end

# ---- FUNCTION TO SEND DUTY CYCLE ----
function set_duty(d::Float64)
    # Clamp duty and convert to VESC integer format
    vesc_duty = Int(round(clamp(d, -1.0, 1.0) * 100000))

    # Create VESC message
    msg = SetDutyCycle(vesc_duty)

    # Encode to Python bytes
    packet = encode(msg)

    # Send raw bytes correctly: wrap as PyObject
    pycall(port.write, PyObject, packet)
end

# ---- COMMAND HANDLER ----
function handle_command(cmd::String)
    global motor_enabled, port

    cmd = strip(lowercase(cmd))

    if cmd == "enable"
        motor_enabled = true
        log("⚡ Motor ENABLED")

    elseif cmd == "disable"
        motor_enabled = false
        try
            set_duty(0.0)
        catch
        end
        log("🛑 Motor DISABLED")

    elseif startswith(cmd, "duty")
        parts = split(cmd)
        if length(parts) == 2 && motor_enabled
            duty = parse(Float64, parts[2])
            try
                set_duty(duty)
                log("➡️ Duty set to $duty")
            catch e
                log("❌ Failed to send duty: $e")
            end
        else
            log("⚠️ Duty ignored (motor disabled or invalid format)")
        end

    else
        log("❓ Unknown command: $cmd")
    end
end

# ---- MAIN LOOP ----
while true
    sock = accept(server)
    println("✅ Client connected: $sock")

    try
        while !eof(sock)
            line = readline(sock)
            log("📥 Command received: $line")
            handle_command(line)
        end
    catch e
        println("❌ Server error: $e")
    finally
        close(sock)
    end
end
