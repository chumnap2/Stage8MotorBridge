module VESCDriver

export connect, arm!, set_duty

# =========================
# 🔌 CONNECT
# =========================
function connect(port::String, baud::Int)
    sock = open(port, "r+")
    Base.flush(sock)
    println("🔌 Connected to VESC on ", port)
    return (port = sock, baud = baud)
end

# =========================
# 🔐 ARM
# =========================
function arm!(vesc)
    try
        # send neutral command
        set_duty(vesc, 0.0)
        sleep(0.5)
    catch e
        println("❌ arm error: ", e)
    end
end

# =========================
# 🔢 CRC16
# =========================
function crc16(data)
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
    return crc & 0xFFFF
end

# =========================
# ⚡ SET DUTY (REAL)
# =========================
function set_duty(vesc, duty::Float64)
    try
        duty = clamp(duty, -0.3, 0.3)

        scaled = Int32(round(duty * 100000))

        payload = UInt8[
            0x05,
            (scaled >> 24) & 0xFF,
            (scaled >> 16) & 0xFF,
            (scaled >> 8) & 0xFF,
            scaled & 0xFF
        ]

        crc = crc16(payload)

        packet = UInt8[]
        push!(packet, 0x02)
        push!(packet, length(payload))
        append!(packet, payload)
        push!(packet, (crc >> 8) & 0xFF)
        push!(packet, crc & 0xFF)
        push!(packet, 0x03)

        write(vesc.port, packet)
        flush(vesc.port)

    catch e
        println("❌ set_duty error: ", e)
    end
end

end
