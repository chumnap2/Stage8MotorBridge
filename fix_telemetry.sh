#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing telemetry (clean replace)..."

# backup
cp "$FILE" "${FILE}.bak_fix_telem"

# remove old telemetry loop
sed -i '/function telemetry_loop/,/^end/d' "$FILE"

# append clean telemetry
cat >> "$FILE" << 'TELEM'

# =========================
# 📡 TELEMETRY LOOP (DRIVER API)
# =========================
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm, last_current, last_voltage

    while true
        try
            if vesc !== nothing

                v = VESCDriver.get_mc_values(vesc)

                last_rpm = hasproperty(v, :rpm) ? v.rpm : 0.0
                last_current = hasproperty(v, :current_motor) ? v.current_motor : 0.0
                last_voltage = hasproperty(v, :v_in) ? v.v_in : 0.0

                println("📊 RPM=$(last_rpm) | I=$(last_current) | V=$(last_voltage)")
            end
        catch e
            println("❌ Telemetry error: ", e)
        end

        sleep(0.2)
    end
end

TELEM

# ensure it's started
grep -q "@async telemetry_loop()" "$FILE" || \
sed -i '/@async motor_loop/a\    @async telemetry_loop()' "$FILE"

echo "✅ Telemetry fixed cleanly"
