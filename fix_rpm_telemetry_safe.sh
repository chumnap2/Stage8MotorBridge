#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Safe RPM + Telemetry restoration..."

# -------------------------
# 0. Backup
# -------------------------
cp "$FILE" "${FILE}.bak_rpm_safe"
echo "📦 Backup created"

# -------------------------
# 1. Ensure safety limit exists
# -------------------------
grep -q "max_duty_rate" "$FILE" || sed -i '/global last_voltage/a global max_duty_rate = 0.01' "$FILE"

echo "✅ Safety limit added"

# -------------------------
# 2. Patch motor loop (safe clamp injection)
# -------------------------
awk '
/error = target_rpm - last_rpm/ {
    print "                error = target_rpm - last_rpm"
    print ""
    print "                k = 0.00001"
    print ""
    print "                change = k * error"
    print "                change = clamp(change, -max_duty_rate, max_duty_rate)"
    print ""
    print "                global last_duty"
    print "                last_duty += change"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ Safe control clamp installed"

# -------------------------
# 3. Re-enable safe telemetry fallback (NO CRASH MODE)
# -------------------------
grep -q "telemetry fallback" "$FILE" || awk '
/function telemetry_loop/ {
    print
    print "    # telemetry fallback safety mode"
    print "    if vesc === nothing"
    print "        println(\"📊 RPM=0 | I=0 | V=0 | DUTY=\" * string(last_duty))"
    print "    end"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ Telemetry safety fallback added"

echo "🎉 SAFE RPM CONTROL RESTORED"
