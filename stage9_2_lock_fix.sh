#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"
DRIVER="VESCDriver.jl"

echo "🚀 Stage 9.2 LOCK FIX START"

# =========================================================
# 1. PATCH VESC DRIVER (INSTRUMENTATION ONLY)
# =========================================================
echo "🔧 Patching VESCDriver.set_duty instrumentation..."

awk '
/function set_duty/ {infun=1}
{
    print
    if (infun && $0 ~ /try/) {
        print "    println(\"📡 VESC DRIVER ENTRY: duty=\", duty)"
    }
    if (infun && $0 ~ /write\\(vesc\\.port/) {
        print "    println(\"📡 VESC WRITE DONE\")"
    }
}
/end/ {infun=0}
' "$DRIVER" > tmp_driver && mv tmp_driver "$DRIVER"


# =========================================================
# 2. PATCH MOTOR SERVER (STATE + CLEAN PARSER)
# =========================================================
echo "🔧 Rewriting handle_client() + STATE lock..."

awk '
/function handle_client/ {infun=1}

infun==0 {print}

/function handle_client/ {
    print "function handle_client(sock)"
    print "    global STATE"
    print "    println(\"🌐 Client connected\")"
    print "    try"
    print "        while isopen(sock)"
    print "            msg = strip(readline(sock))"
    print "            try"
    print "                parts = split(msg)"
    print "                if length(parts) == 1"
    print "                    STATE[:last_duty] = clamp(parse(Float64, parts[1]), -0.2, 0.2)"
    print "                    STATE[:last_command_time] = time()"
    print "                    println(\"📥 CMD → duty = \", STATE[:last_duty])"
    print "                elseif parts[1] == \"duty\""
    print "                    STATE[:last_duty] = clamp(parse(Float64, parts[2]), -0.2, 0.2)"
    print "                    STATE[:last_command_time] = time()"
    print "                    println(\"📥 CMD → duty = \", STATE[:last_duty])"
    print "                elseif parts[1] == \"stop\""
    print "                    STATE[:last_duty] = 0.0"
    print "                    STATE[:last_command_time] = time()"
    print "                    println(\"🛑 STOP\")"
    print "                else"
    print "                    println(\"⚠️ Unknown command: \", msg)"
    print "                end"
    print "            catch e"
    print "                println(\"⚠️ Parse error: \", msg, \" | \", e)"
    print "            end"
    print "        end"
    print "    catch e"
    print "        println(\"❌ Client error: \", e)"
    print "    end"
    print "    close(sock)"
    print "end"
    infun=0
}
' "$FILE" > tmp_server && mv tmp_server "$FILE"


# =========================================================
# 3. VERIFY PATCH
# =========================================================
echo "🔍 Verifying instrumentation..."

grep -q "VESC DRIVER ENTRY" "$DRIVER" && echo "✅ driver entry instrumented"
grep -q "VESC WRITE DONE" "$DRIVER" && echo "✅ driver write instrumented"
grep -q "STATE" "$FILE" && echo "✅ STATE system active"

echo "🎉 STAGE 9.2 LOCK FIX COMPLETE"
