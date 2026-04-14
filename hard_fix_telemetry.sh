#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔍 Checking telemetry state..."

grep -n "function telemetry_loop" "$FILE" || echo "❌ telemetry_loop NOT FOUND"
grep -n "@async telemetry_loop" "$FILE" || echo "❌ telemetry start NOT FOUND"

echo "🔧 Applying HARD FIX..."

cp "$FILE" "${FILE}.bak_hard_fix"

# -------------------------------------------------
# 1. REMOVE ANY BROKEN TELEMETRY REFERENCES
# -------------------------------------------------
sed -i '/telemetry_loop()/d' "$FILE"
sed -i '/last_rpm/d' "$FILE"
sed -i '/last_current/d' "$FILE"
sed -i '/last_voltage/d' "$FILE"

# -------------------------------------------------
# 2. ADD GLOBALS CLEANLY
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
# 3. ADD TELEMETRY FUNCTION (FORCE)
# -------------------------------------------------
cat >> "$FILE" << 'FUNC'

# =========================
# 📡 TELEMETRY LOOP (5 Hz)
# =========================
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm, last_current, last_voltage, last_duty, running

    while running
        println("📡 heartbeat")   # <-- PROOF IT RUNS

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
# 4. FORCE INSERT INTO main()
# -------------------------------------------------
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ HARD FIX COMPLETE"
