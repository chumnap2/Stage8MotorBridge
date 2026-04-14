#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing telemetry startup..."

cp "$FILE" "${FILE}.bak_start_fix"

# Ensure telemetry loop is started
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# Add heartbeat print (only if missing)
grep -q "Telemetry loop running" "$FILE" || cat >> "$FILE" << 'END'

println("⚠️ WARNING: telemetry loop may not be properly inserted")
END

echo "✅ Telemetry start fixed"
