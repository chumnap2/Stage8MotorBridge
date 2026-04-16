#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing TCP parser (repo-accurate)..."

# backup
cp "$FILE" "${FILE}.bak_tcp_parser"

awk '
BEGIN {inblock=0}

# detect readline line
/msg = readline\(sock\)/ {
    print
    print "            line = strip(msg)"
    print "            parts = split(line)"
    print ""
    print "            if length(parts) == 1"
    print "                val = parse(Float64, parts[1])"
    print "                global last_duty, last_command_time"
    print "                last_duty = clamp(val, -0.2, 0.2)"
    print "                last_command_time = time()"
    print "                println(\"📥 CMD → duty = \", last_duty)"
    print ""
    print "            elseif parts[1] == \"duty\""
    print "                val = parse(Float64, parts[2])"
    print "                global last_duty, last_command_time"
    print "                last_duty = clamp(val, -0.2, 0.2)"
    print "                last_command_time = time()"
    print "                println(\"📥 CMD → duty = \", last_duty)"
    print ""
    print "            elseif parts[1] == \"stop\""
    print "                global last_duty"
    print "                last_duty = 0.0"
    print "                println(\"🛑 STOP\")"
    print ""
    print "            else"
    print "                println(\"⚠️ Unknown command\")"
    print "            end"
    inblock=1
    next
}

# skip old parser lines until we hit next blank or println
inblock==1 {
    if ($0 ~ /^\s*$/) {
        inblock=0
        print
    }
    next
}

{print}

' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "✅ TCP parser fixed safely"
