#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Applying lock + telemetry fix..."

# -----------------------------
# 0. Backup
# -----------------------------
cp "$FILE" "${FILE}.bak_lockfix"
echo "📦 Backup: ${FILE}.bak_lockfix"

# -----------------------------
# 1. Comment out telemetry start
# -----------------------------
sed -i 's/@async telemetry_loop()/# @async telemetry_loop()/g' "$FILE"

# -----------------------------
# 2. Add global lock (if not present)
# -----------------------------
grep -q "vesc_lock" "$FILE" || awk '
/global last_duty/ {
    print
    print "global vesc_lock = ReentrantLock()"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# -----------------------------
# 3. Fix motor_loop with lock
# -----------------------------
awk '
/send_duty\(last_duty\)/ {
    print "        lock(vesc_lock) do"
    print "            send_duty(last_duty)"
    print "        end"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# -----------------------------
# 4. Fix telemetry block safely
# -----------------------------
awk '
/VESCDriver.get_values/ {
    print "                lock(vesc_lock) do"
    print "                    v = VESCDriver.get_values(vesc)"
    print ""
    print "                    last_rpm = hasproperty(v, :rpm) ? v.rpm : 0.0"
    print "                    last_current = hasproperty(v, :current_motor) ? v.current_motor : 0.0"
    print "                    last_voltage = hasproperty(v, :v_in) ? v.v_in : 0.0"
    print "                end"
    skip=1
    next
}
skip && /println/ {
    skip=0
}
!skip {print}
' "$FILE" > tmp && mv tmp "$FILE"

# -----------------------------
# 5. Verify
# -----------------------------
echo "🔍 Verifying..."

grep -q "vesc_lock" "$FILE" && echo "✅ lock added"
grep -q "lock(vesc_lock)" "$FILE" && echo "✅ lock usage added"
grep -q "# @async telemetry_loop()" "$FILE" && echo "✅ telemetry disabled"

echo "🎉 FIX COMPLETE"
