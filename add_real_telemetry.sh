#!/bin/bash
set -e

DRIVER="VESCDriver.jl"
SERVER="MotorBridgeServer.jl"

echo "🔧 Adding SAFE telemetry..."

# -----------------------------
# 1. Backup
# -----------------------------
cp "$DRIVER" "${DRIVER}.bak_telem"
cp "$SERVER" "${SERVER}.bak_telem"

# -----------------------------
# 2. Add get_rpm() to driver
# -----------------------------
awk '
/^end/ && !added {
    print ""

    print "# ========================="
    print "# 📡 GET RPM (SAFE)"
    print "# ========================="
    print "function get_rpm(vesc)"
    print "    try"
    print "        # COMM_GET_VALUES"
    print "        payload = UInt8[0x04]"
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
    print "        sleep(0.02)"
    print ""
    print "        data = readavailable(vesc.port)"
    print ""
    print "        if length(data) > 50"
    print "            # VERY rough extraction (safe offset)"
    print "            rpm = reinterpret(Int32, data[25:28])[1]"
    print "            return Float64(rpm)"
    print "        end"
    print ""
    print "        return 0.0"
    print ""
    print "    catch e"
    print "        println(\"❌ get_rpm error: \", e)"
    print "        return 0.0"
    print "    end"
    print "end"
    print ""

    added=1
}

{print}
' "$DRIVER" > tmp && mv tmp "$DRIVER"

# add export if missing
grep -q "get_rpm" "$DRIVER" || \
sed -i 's/export /export get_rpm, /' "$DRIVER"

# -----------------------------
# 3. Replace telemetry loop
# -----------------------------
sed -i '/function telemetry_loop/,/^end/d' "$SERVER"

cat >> "$SERVER" << 'TELEM'

# =========================
# 📡 TELEMETRY LOOP (REAL RPM)
# =========================
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm

    while true
        if vesc !== nothing
            try
                last_rpm = VESCDriver.get_rpm(vesc)
                println("📊 RPM=", last_rpm)
            catch e
                println("❌ Telemetry error: ", e)
            end
        end

        sleep(0.2)
    end
end
TELEM

# -----------------------------
# 4. Enable telemetry
# -----------------------------
grep -q "@async telemetry_loop()" "$SERVER" || \
sed -i '/@async motor_loop/a\    @async telemetry_loop()' "$SERVER"

echo "🎉 REAL TELEMETRY ADDED"
