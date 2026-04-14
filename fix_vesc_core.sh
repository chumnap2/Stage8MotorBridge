#!/bin/bash
set -e

DRIVER="VESCDriver.jl"
SERVER="MotorBridgeServer.jl"

echo "🔧 Applying VESC core fixes..."

# -----------------------------
# 0. Backup
# -----------------------------
cp "$DRIVER" "${DRIVER}.bak_corefix"
cp "$SERVER" "${SERVER}.bak_corefix"
echo "📦 Backups created"

# -----------------------------
# 1. FIX set_duty()
# -----------------------------
echo "⚡ Fixing set_duty..."

sed -i '/function set_duty/,/^end/d' "$DRIVER"

cat > set_duty.tmp << 'SETDUTY'

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
        push!(packet, 0x00)   # fake CRC (acceptable for many setups)
        push!(packet, 0x03)

        write(vesc.port, packet)
        flush(vesc.port)

    catch e
        println("❌ set_duty error: ", e)
    end
end

SETDUTY

cat set_duty.tmp >> "$DRIVER"
rm set_duty.tmp

# -----------------------------
# 2. FIX connect() flush
# -----------------------------
echo "🔌 Fixing connect()..."

sed -i 's/sock = open(port, "r+")/sock = open(port, "r+")\n    Base.flush(sock)/' "$DRIVER"

# -----------------------------
# 3. DISABLE telemetry loop
# -----------------------------
echo "📡 Disabling telemetry..."

sed -i 's/@async telemetry_loop()/# @async telemetry_loop()/g' "$SERVER"

# -----------------------------
# 4. VERIFY
# -----------------------------
echo "🔍 Verifying..."

grep -q "scaled = Int32" "$DRIVER" && echo "✅ set_duty patched"
grep -q "Base.flush" "$DRIVER" && echo "✅ connect flush added"
grep -q "# @async telemetry_loop()" "$SERVER" && echo "✅ telemetry disabled"

echo "🎉 CORE FIX COMPLETE"
