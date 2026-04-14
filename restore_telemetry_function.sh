#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Restoring telemetry function..."

cp "$FILE" "${FILE}.bak_restore_func"

# Only add if missing
if grep -q "function telemetry_loop" "$FILE"; then
    echo "⚠️ telemetry_loop already exists — skipping insert"
    exit 0
fi

cat > telemetry_func.jl << 'FUNC'
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

                last_rpm = hasproperty(v, :rpm) ? v.rpm : 0.0
                last_current = hasproperty(v, :current_motor) ? v.current_motor : 0.0
                last_voltage = hasproperty(v, :v_in) ? v.v_in : 0.0

                println("📊 RPM=$(last_rpm) | I=$(last_current)A | V=$(last_voltage)V | DUTY=$(last_duty)")

            catch e
                println("❌ Telemetry error: ", e)
            end
        end

        sleep(0.2)
    end

    println("🛑 Telemetry loop stopped")
end
FUNC

# Append safely
cat telemetry_func.jl >> "$FILE"
rm telemetry_func.jl

echo "✅ telemetry_loop restored"
