module VESCDriver

using LibSerialPort

export connect, arm!, set_duty

mutable struct VESC
    port
end

# =====================================================
# CONNECT
# =====================================================
function connect(device::String, baud::Int)
    port = LibSerialPort.sp_get_port_by_name(device)

    if port === C_NULL
        error("VESC port not found: $device")
    end

    LibSerialPort.sp_open(port, LibSerialPort.SP_MODE_READ_WRITE)

    LibSerialPort.sp_set_baudrate(port, baud)
    LibSerialPort.sp_set_bits(port, 8)
    LibSerialPort.sp_set_parity(port, LibSerialPort.SP_PARITY_NONE)
    LibSerialPort.sp_set_stopbits(port, 1)
    LibSerialPort.sp_set_flowcontrol(port, LibSerialPort.SP_FLOWCONTROL_NONE)

    println("✅ VESC connected on $device")

    return VESC(port)
end

# =====================================================
# CRC16 (REQUIRED FOR VESC)
# =====================================================
function crc16(data::Vector{UInt8})
    crc = UInt16(0)

    for b in data
        crc ⊻= UInt16(b) << 8
        for _ in 1:8
            if (crc & 0x8000) != 0
                crc = (crc << 1) ⊻ 0x1021
            else
                crc <<= 1
            end
        end
    end

    return crc
end

# =====================================================
# SEND PACKET (WITH CRC)
# =====================================================
function send_packet(v::VESC, payload::Vector{UInt8})
    packet = UInt8[]

    push!(packet, 0x02)              # START
    push!(packet, length(payload))   # LEN
    append!(packet, payload)         # PAYLOAD

    crc = crc16(payload)

    push!(packet, (crc >> 8) & 0xFF) # CRC HIGH
    push!(packet, crc & 0xFF)        # CRC LOW

    push!(packet, 0x03)              # END

    LibSerialPort.sp_nonblocking_write(v.port, packet)
end

# =====================================================
# ARM
# =====================================================
function arm!(v::VESC)
    println("🔐 Arming VESC")
    set_duty(v, 0.0)
end

# =====================================================
# SET DUTY
# =====================================================
function set_duty(v::VESC, duty::Float64)
    duty = clamp(duty, -0.3, 0.3)

    scaled = Int32(round(duty * 100000))

    payload = UInt8[
        0x05,
        (scaled >> 24) & 0xFF,
        (scaled >> 16) & 0xFF,
        (scaled >> 8) & 0xFF,
        scaled & 0xFF
    ]

    send_packet(v, payload)
end

end
