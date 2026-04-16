# ==========================================
# STAGE 9 STABLE (WORKING)
# TCP → VESC DUTY CONTROL CONFIRMED
# Date: 2026-04-16
# ==========================================

module VESCDriver

export VESC, connect, set_duty

# =========================
# 🔌 VESC STRUCT
# =========================
struct VESC
    port::IO
end

# =========================
# 🔌 CONNECT
# =========================
function connect(port="/dev/vesc", baud=115200)
    println("🔌 Connecting to VESC on $port ...")
    io = open(port, "w+")
    println("🔌 Connected")
    return VESC(io)
end

# =========================
# 🔢 CRC16 (VESC)
# =========================
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

# =========================
# ⚡ SET DUTY
# =========================
function set_duty(vesc::VESC, duty::Float64)
    try
        duty = clamp(duty, -0.3, 0.3)

        value = Int32(duty * 100000)

        payload = UInt8[
            5,
            (value >> 24) & 0xFF,
            (value >> 16) & 0xFF,
            (value >> 8) & 0xFF,
            value & 0xFF
        ]

        crc = crc16(payload)

        packet = UInt8[
            0x02,
            length(payload),
            payload...,
            (crc >> 8) & 0xFF,
            crc & 0xFF,
            0x03
        ]

        println("📦 DUTY=", duty)
        println("📦 VALUE=", value)
        println("📦 PACKET=", packet)

        write(vesc.port, packet)
        flush(vesc.port)

    catch e
        println("❌ set_duty error: ", e)
    end
end

end # module
