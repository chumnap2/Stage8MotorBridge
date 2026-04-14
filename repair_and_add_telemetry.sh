#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Starting full repair + telemetry patch..."

# -------------------------------------------------
# 0. Restore from backup (CRITICAL)
# -------------------------------------------------
if [ -f "${FILE}.bak_safe" ]; then
    echo "♻️ Restoring from bak_safe..."
    cp "${FILE}.bak_safe" "$FILE"
elif [ -f "${FILE}.bak_telemetry" ]; then
    echo "♻️ Restoring from bak_telemetry..."
    cp "${FILE}.bak_telemetry" "$FILE"
else
    echo "⚠️ No backup found — proceeding with cleanup only"
fi

# -------------------------------------------------
# 1. Remove any corrupted telemetry remnants
# -------------------------------------------------
echo "🧹 Cleaning broken telemetry blocks..."

sed -i '/TELEMETRY LOOP/,+40d' "$FILE"
sed -i '/AUTO-INJECTED/d' "$FILE"
sed -i '/last_rpm/d' "$FILE"
sed -i '/last_current/d' "$FILE"
sed -i '/last_voltage/d' "$FILE"

# -------------------------------------------------
# 2. Inject globals safely
# -------------------------------------------------
awk '
/global last_duty/ {
    print
    print "global last_rpm = 0.0"
    print "global last_current = 0.0"
    print "global last_voltage = 0.0"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# -------------------------------------------------
# 3. Append clean telemetry block
# -------------------------------------------------
cat > telemetry_block.jl << 'TELOOP'
# =========================
# 📡 TELEMETRY LOOP (5 Hz)
# =========================
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm, last_current, last_voltage, last_duty, running

    while running
        if vesc !== nothing
            try
                v = VESCDriver.get_values(vesc)

                last_rpm = getfield(v, :rpm, 0.0)
                last_current = getfield(v, :current_motor, 0.0)
                last_voltage = getfield(v, :v_in, 0.0)

                println("📊 RPM=$(last_rpm) | I=$(last_current)A | V=$(last_voltage)V | DUTY=$(last_duty)")

            catch e
                println("❌ Telemetry error: ", e)
            end
        end

        sleep(0.2)
    end

    println("🛑 Telemetry loop stopped")
end
TELOOP

cat telemetry_block.jl >> "$FILE"
rm telemetry_block.jl

# -------------------------------------------------
# 4. Inject into main()
# -------------------------------------------------
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()   # AUTO-INJECTED"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# -------------------------------------------------
# 5. Verify patch
# -------------------------------------------------
echo "🔍 Verifying..."

grep -q "telemetry_loop" "$FILE" && echo "✅ telemetry_loop present"
grep -q "last_rpm" "$FILE" && echo "✅ globals present"

echo "🎉 Repair + telemetry patch COMPLETE"
