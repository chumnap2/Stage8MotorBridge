using SerialPorts

println("Opening VESC...")
vesc = SerialPort("/dev/ttyACM0", 115200)

function crc16(data::Vector{UInt8})
    crc = 0
    for b in data
        crc = crc ⊻ (Int(b) << 8)
        for _ in 1:8
            if (crc & 0x8000) != 0
                crc = (crc << 1) ⊻ 0x1021
            else
                crc <<= 1
            end
            crc &= 0xFFFF
        end
    end
    return crc
end

function vesc_packet(payload::Vector{UInt8})
    len = Base.length(payload)

    packet = UInt8[0x02, UInt8(len)]
    append!(packet, payload)

    crc = crc16(payload)

    push!(packet, UInt8(crc >> 8))
    push!(packet, UInt8(crc & 0xFF))
    push!(packet, 0x03)

    return packet
end


function set_duty(vesc, duty)
    value = Int32(duty * 100_000)
    payload = UInt8[5]
    for shift in (24,16,8,0)
        push!(payload, UInt8((value >> shift) & 0xff))
    end

    pkt = vesc_packet(payload)
    write(vesc, pkt)
    flush(vesc)
    println("✅ Duty sent: ", duty)
end

sleep(1)

println("⚡ Spinning motor at 5%...")
set_duty(vesc, 0.05)

sleep(5)

println("🛑 Stopping motor...")
set_duty(vesc, 0.0)

close(vesc)
println("Done.")
