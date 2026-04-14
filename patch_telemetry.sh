#!/bin/bash

FILE="MotorBridgeServer.jl"

echo "🔧 Patching telemetry into $FILE ..."

# Backup first
cp $FILE ${FILE}.bak_telemetry

# Insert global state AFTER existing globals (safe append block)
awk '
/global last_duty/ {
    print
    print "global last_rpm = 0.0"
    print "global last_current = 0.0"
    print "global last_voltage = 0.0"
    next
}
{print}
' $FILE > tmp && mv tmp $FILE

echo "➕ Injecting telemetry_loop() ..."

cat >> $FILE << 'TELOOP'

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

                last_rpm = v.rpm
                last_current = v.current_motor
                last_voltage = v.v_in

                println("📊 RPM=$(last_rpm) | I=$(last_current)A | V=$(last_voltage)V | DUTY=$(last_duty)")

            catch e
                println("❌ Telemetry error: ", e)
            end
        end

        sleep(0.2)
    end
end
TELOOP

echo "⚙️ Injecting telemetry into main() ..."

awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()   # AUTO-INJECTED"
    next
}
{print}
' $FILE > tmp && mv tmp $FILE

echo "✅ Patch complete."
echo "👉 Backup saved as MotorBridgeServer.jl.bak_telemetry"
