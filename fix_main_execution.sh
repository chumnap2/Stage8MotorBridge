#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing main() execution order..."

cp "$FILE" "${FILE}.bak_main_fix"

# Replace main() completely with correct structure
awk '
/function main\(\)/ {
    print "function main()"
    print "    println(\"🚀 Starting MotorBridgeServer (FINAL)\")"
    print ""
    print "    connect_vesc()"
    print ""
    print "    if vesc === nothing"
    print "        println(\"❌ Cannot start: VESC not connected\")"
    print "        return"
    print "    end"
    print ""
    print "    @async motor_loop()"
    print "    @async telemetry_loop()"
    print ""
    print "    println(\"🚀 All loops started\")"
    print ""
    print "    start_server()   # blocking LAST"
    print "end"
    skip=1
    next
}

skip==1 && /end/ {
    skip=0
    next
}

skip!=1 {print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ main() FIXED"
