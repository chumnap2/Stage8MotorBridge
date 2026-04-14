#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Forcing telemetry enable..."

cp "$FILE" "${FILE}.bak_force_enable"

# Remove any broken/duplicate telemetry start lines
sed -i '/telemetry_loop()/d' "$FILE"

# Insert telemetry start AFTER motor_loop
awk '
/@async motor_loop/ {
    print
    print "    @async telemetry_loop()"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ Telemetry ENABLED"
