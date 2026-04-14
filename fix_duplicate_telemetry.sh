#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🧹 Cleaning duplicate telemetry blocks..."

cp "$FILE" "${FILE}.bak_dups"

# -------------------------------------------------
# 1. REMOVE ALL telemetry_loop FUNCTIONS
# -------------------------------------------------
awk '
BEGIN {skip=0}
function_seen == 1 && /function telemetry_loop/ {skip=1}
skip==1 && /end/ {skip=0; next}
skip==0 {print}
' "$FILE" > tmp && mv tmp "$FILE"

# -------------------------------------------------
# 2. REMOVE ALL async calls
# -------------------------------------------------
sed -i '/@async telemetry_loop/d' "$FILE"

# -------------------------------------------------
# 3. ADD SINGLE CLEAN FUNCTION AT END
# -------------------------------------------------
cat >> "$FILE" << 'FUNC'

# =========================
# 📡 CLEAN TELEMETRY LOOP (SINGLE)
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
end
FUNC

# -------------------------------------------------
# 4. INSERT SINGLE START LINE INTO main()
# -------------------------------------------------
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ CLEAN TELEMETRY FIX COMPLETE"
