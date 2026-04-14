#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"
DRV="VESCDriver.jl"

echo "🚀 FULL RESET FIX START"

# ----------------------------
# 1. BACKUP EVERYTHING
# ----------------------------
cp "$FILE" "${FILE}.bak_fullreset"
cp "$DRV" "${DRV}.bak_fullreset"

echo "📦 Backups created"

# ----------------------------
# 2. FIX listen() SYNTAX
# ----------------------------
sed -i 's/listen("127.0.0.1",/listen(ip"127.0.0.1",/g' "$FILE"
sed -i 's/listen(127.0.0.1,/listen(ip"127.0.0.1",/g' "$FILE"

# ----------------------------
# 3. REMOVE ALL BROKEN TELEMETRY PATCHES
# ----------------------------
sed -i '/TELEMETRY LOOP/,+200d' "$FILE"
sed -i '/telemetry_loop/d' "$FILE"
sed -i '/get_mc_values/d' "$FILE"
sed -i '/get_values/d' "$FILE"

# ----------------------------
# 4. FORCE CLEAN set_duty (ONLY ONE VERSION)
# ----------------------------
awk '
BEGIN {skip=0}
/function set_duty/ {skip=1}
skip==1 && /end/ {skip=0; next}
skip==0 {print}
' "$DRV" > tmp && mv tmp "$DRV"

cat >> "$DRV" << 'EOF2'

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

        packet = UInt8[]
        push!(packet, 0x02)
        push!(packet, length(payload))
        append!(packet, payload)
        push!(packet, 0x00)
        push!(packet, 0x03)

        write(vesc.port, packet)
        flush(vesc.port)

    catch e
        println("❌ set_duty error: ", e)
    end
end

EOF2

echo "✅ set_duty FORCE RESET"

# ----------------------------
# 5. REMOVE MODULE CONFUSION IN REPL CACHE
# ----------------------------
echo "⚠️ NOTE: restart Julia after this step"

echo "🎉 FULL RESET COMPLETE"
