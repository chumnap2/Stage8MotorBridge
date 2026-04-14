#!/bin/bash
set -e

SERVER="MotorBridgeServer.jl"
DRIVER="VESCDriver.jl"

echo "🔧 Fixing telemetry to use driver API..."

# -----------------------------
# 0. Backup
# -----------------------------
cp "$SERVER" "${SERVER}.bak_driverfix"
cp "$DRIVER" "${DRIVER}.bak_driverfix"
echo "📦 Backups created"

# -----------------------------
# 1. Remove custom telemetry from driver
# -----------------------------
echo "🧹 Removing custom get_values + decode..."

sed -i '/function get_values/,/end/d' "$DRIVER"
sed -i '/function decode_values_safe/,/end/d' "$DRIVER"

# -----------------------------
# 2. Remove old telemetry_loop
# -----------------------------
echo "🧹 Removing old telemetry_loop..."

sed -i '/function telemetry_loop/,/^end/d' "$SERVER"

# -----------------------------
# 3. Append clean telemetry_loop
# -----------------------------
cat > telemetry_block.tmp << 'TELEOF'

# =========================
# 📡 TELEMETRY LOOP (5 Hz)
# =========================
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm, last_current, last_voltage, last_duty

    while true
        try
            if vesc !== nothing

                # 🔥 Use driver-level API
                v = VESCDriver.get_mc_values(vesc)

                last_rpm = v.rpm
                last_current = v.current_motor
                last_voltage = v.v_in

                println("📊 RPM=$(last_rpm) | I=$(last_current) | V=$(last_voltage) | DUTY=$(last_duty)")
            end
        catch e
            println("❌ Telemetry error: ", e)
        end

        sleep(0.2)
    end
end
TELEOF

cat telemetry_block.tmp >> "$SERVER"
rm telemetry_block.tmp

# -----------------------------
# 4. Ensure telemetry is started
# -----------------------------
grep -q "@async telemetry_loop()" "$SERVER" || \
sed -i '/@async motor_loop/a\    @async telemetry_loop()' "$SERVER"

# -----------------------------
# 5. Verify
# -----------------------------
echo "🔍 Verifying..."

grep -q "get_mc_values" "$SERVER" && echo "✅ using driver telemetry"
grep -q "telemetry_loop" "$SERVER" && echo "✅ telemetry_loop present"

echo "🎉 DRIVER TELEMETRY FIX COMPLETE"
