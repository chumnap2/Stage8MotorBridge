#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing telemetry inner block (safe replace)..."

# backup
cp "$FILE" "${FILE}.bak_inner_fix"

# replace ONLY the inner try/catch block of telemetry_loop
awk '
BEGIN {inblock=0}

/function telemetry_loop/ {print; inblock=1; next}

/try/ && inblock==1 {
    print "        try"
    print "            v = VESCDriver.get_values(vesc)"
    print ""
    print "            last_rpm = hasproperty(v, :rpm) ? v.rpm : 0.0"
    print "            last_current = hasproperty(v, :current_motor) ? v.current_motor : 0.0"
    print "            last_voltage = hasproperty(v, :v_in) ? v.v_in : 0.0"
    print ""
    print "            println(\"📊 RPM=$(last_rpm) | I=$(last_current)A | V=$(last_voltage)V | DUTY=$(last_duty)\")"
    print ""
    print "        catch e"
    print "            println(\"❌ Telemetry error: \", e)"
    print "        end"
    skip=1
    next
}

# skip old block until end of catch
skip==1 && /end/ {
    skip=0
    next
}

skip==1 {next}

{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ Telemetry inner block fixed"
echo "📦 Backup: ${FILE}.bak_inner_fix"
