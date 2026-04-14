#!/bin/bash

set -e

FILE="MotorBridgeServer.jl"

echo "🔧 SAFE telemetry patch starting..."

# backup
cp "$FILE" "${FILE}.bak_safe"

echo "📦 Backup created: ${FILE}.bak_safe"

# -----------------------------
# 1. Inject globals safely
# -----------------------------
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

# -----------------------------
# 2. Create telemetry block safely (NO heredoc into target file)
# -----------------------------
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

# -----------------------------
# 3. Append safely to file
# -----------------------------
cat telemetry_block.jl >> "$FILE"

# -----------------------------
# 4. Inject into main()
# -----------------------------
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()   # AUTO-INJECTED"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# cleanup
rm -f telemetry_block.jl

echo "✅ SAFE telemetry patch complete"
