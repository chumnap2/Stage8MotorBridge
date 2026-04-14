#!/bin/bash
set -e

FILE="VESCDriver.jl"

echo "🔧 Fixing set_duty with REAL CRC..."

cp "$FILE" "${FILE}.bak_crc"

# remove old set_duty
sed -i '/function set_duty/,/^end/d' "$FILE"

# insert correct implementation
awk '
/^end/ && !done {
    print ""

    print "# ========================="
    print "# ⚡ SET DUTY (REAL CRC)"
    print "# ========================="
    print "function set_duty(vesc, duty::Float64)"
    print "    try"
    print "        duty = clamp(duty, -0.3, 0.3)"
    print "        scaled = Int32(round(duty * 100000))"
    print ""
    print "        payload = UInt8["
    print "            0x05,"
    print "            (scaled >> 24) & 0xFF,"
    print "            (scaled >> 16) & 0xFF,"
    print "            (scaled >> 8) & 0xFF,"
    print "            scaled & 0xFF"
    print "        ]"
    print ""
    print "        crc = crc16(payload)"
    print ""
    print "        packet = UInt8[]"
    print "        push!(packet, 0x02)"
    print "        push!(packet, length(payload))"
    print "        append!(packet, payload)"
    print "        push!(packet, (crc >> 8) & 0xFF)"
    print "        push!(packet, crc & 0xFF)"
    print "        push!(packet, 0x03)"
    print ""
    print "        write(vesc.port, packet)"
    print "        flush(vesc.port)"
    print ""
    print "    catch e"
    print "        println(\"❌ set_duty error: \", e)"
    print "    end"
    print "end"
    print ""

    print "# ========================="
    print "# 🔢 CRC16 (VESC)"
    print "# ========================="
    print "function crc16(data)"
    print "    crc = UInt16(0)"
    print "    for b in data"
    print "        crc ⊻= UInt16(b) << 8"
    print "        for _ in 1:8"
    print "            if (crc & 0x8000) != 0"
    print "                crc = (crc << 1) ⊻ 0x1021"
    print "            else"
    print "                crc <<= 1"
    print "            end"
    print "        end"
    print "    end"
    print "    return crc & 0xFFFF"
    print "end"
    print ""

    done=1
}

{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "🎉 CRC FIX APPLIED"
