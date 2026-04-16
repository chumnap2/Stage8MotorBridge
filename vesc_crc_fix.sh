#!/bin/bash
set -e

FILE="VESCDriver.jl"

echo "🚀 VESC CRC + PACKET FIX START"

# =========================================================
# 1. ADD CRC16 FUNCTION (IF NOT EXISTS)
# =========================================================
if ! grep -q "function crc16" "$FILE"; then
cat >> "$FILE" << 'CRC'
# =========================
# CRC16 (VESC compatible)
# =========================
function crc16(data::Vector{UInt8})
    crc = UInt16(0x0000)
    for b in data
        crc = crc ⊻ (UInt16(b) << 8)
        for i in 1:8
            if (crc & 0x8000) != 0
                crc = (crc << 1) ⊻ 0x1021
            else
                crc <<= 1
            end
        end
    end
    return crc
end
CRC
fi

# =========================================================
# 2. REPLACE set_duty COMPLETELY
# =========================================================
awk '
/function set_duty/ {infun=1}

infun==0 {print; next}

infun==1 && /function set_duty/ {
    print "function set_duty(vesc::VESC, duty::Float64)"
    print "    try"
    print "        duty = clamp(duty, -0.3, 0.3)"
    print ""
    print "        payload = Vector{UInt8}()"
    print "        push!(payload, 0x05)"
    print "        append!(payload, reinterpret(UInt8, [Float32(duty)]))"
    print ""
    print "        len = length(payload)"
    print "        packet = Vector{UInt8}()"
    print ""
    print "        push!(packet, 0x02)"
    print "        push!(packet, UInt8(len))"
    print ""
    print "        append!(packet, payload)"
    print ""
    print "        crc = crc16(payload)"
    print "        push!(packet, UInt8(crc >> 8))"
    print "        push!(packet, UInt8(crc & 0xFF))"
    print ""
    print "        push!(packet, 0x03)"
    print ""
    print "        println(\"📡 VESC DRIVER ENTRY: duty=\", duty)"
    print ""
    print "        write(vesc.port, packet)"
    print "        flush(vesc.port)"
    print ""
    print "        println(\"📡 VESC WRITE DONE\")"
    print "        println(\"📦 PACKET=\", packet)"
    print ""
    print "    catch e"
    print "        println(\"❌ set_duty error: \", e)"
    print "    end"
    print "end"
    infun=0
    next
}
' "$FILE" > tmp && mv tmp "$FILE"

# =========================================================
# 3. VERIFY
# =========================================================
echo "🔍 Verifying patch..."

grep -q "crc16" "$FILE" && echo "✅ CRC16 present"
grep -q "VESC WRITE DONE" "$FILE" && echo "✅ instrumentation present"
grep -q "PACKET=" "$FILE" && echo "✅ packet debug enabled"

echo "🎉 VESC CRC FIX COMPLETE"
