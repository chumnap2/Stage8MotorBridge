#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Stage8 control fix (TCP + watchdog + debug)..."

# backup
cp "$FILE" "${FILE}.bak_stage8_control"

# -------------------------
# 1. Replace TCP handler block
# -------------------------
awk '
BEGIN {skip=0}

/# === TCP COMMAND HANDLER START ===/ {print; skip=1; next}
/# === TCP COMMAND HANDLER END ===/ {
    skip=0

    print "    parts = split(line)"
    print ""
    print "    if length(parts) == 1"
    print "        val = parse(Float64, parts[1])"
    print ""
    print "        global last_duty"
    print "        global last_command_time"
    print ""
    print "        last_duty = clamp(val, -0.2, 0.2)"
    print "        last_command_time = time()"
    print ""
    print "        println(\"📥 CMD → duty = \", last_duty)"
    print ""
    print "    elseif parts[1] == \"duty\""
    print "        val = parse(Float64, parts[2])"
    print ""
    print "        global last_duty"
    print "        global last_command_time"
    print ""
    print "        last_duty = clamp(val, -0.2, 0.2)"
    print "        last_command_time = time()"
    print ""
    print "        println(\"📥 CMD → duty = \", last_duty)"
    print ""
    print "    elseif parts[1] == \"stop\""
    print "        global last_duty"
    print "        last_duty = 0.0"
    print ""
    print "        println(\"🛑 STOP\")"
    print ""
    print "    else"
    print "        println(\"⚠️ Unknown command\")"
    print "    end"

    print
    print "# === TCP COMMAND HANDLER END ==="
    next
}

skip==0 {print}
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

# -------------------------
# 2. Relax watchdog timeout
# -------------------------
sed -i 's/time() - last_command_time > 2.0/time() - last_command_time > 5.0/g' "$FILE"

# -------------------------
# 3. Add debug print inside motor_loop
# -------------------------
sed -i '/function motor_loop()/a\    println("⏱ idle=", time() - last_command_time)' "$FILE"

echo "✅ Stage8 control fix applied"
