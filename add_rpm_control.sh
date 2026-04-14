#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Adding RPM control (SAFE MODE)..."

# -------------------------
# Backup
# -------------------------
cp "$FILE" "${FILE}.bak_rpm"
echo "📦 Backup created"

# -------------------------
# 1. Add globals (if missing)
# -------------------------
grep -q "target_rpm" "$FILE" || sed -i '/global last_voltage/a global target_rpm = 0.0\nglobal control_enabled = false' "$FILE"

echo "✅ Globals added"

# -------------------------
# 2. Add RPM command
# -------------------------
awk '
/elseif parts\[1\] == "stop"/ && !done {
    print
    print ""
    print "            elseif parts[1] == \"rpm\""
    print "                global target_rpm, control_enabled"
    print "                target_rpm = parse(Float64, parts[2])"
    print "                control_enabled = true"
    print ""
    print "                println(\"🎯 Target RPM: \", target_rpm)"
    print "                write(sock, \"RPM SET\\n\")"
    done=1
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ RPM command added"

# -------------------------
# 3. Patch motor loop (inject control logic)
# -------------------------
awk '
/VESCDriver.set_duty/ && !done {
    print "            if control_enabled"
    print "                error = target_rpm - last_rpm"
    print "                k = 0.00001"
    print "                global last_duty"
    print "                last_duty += k * error"
    print "                last_duty = clamp(last_duty, -0.2, 0.2)"
    print "            end"
    print ""
    print $0
    done=1
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ Motor loop upgraded"

echo "🎉 RPM CONTROL INSTALLED SAFELY"
