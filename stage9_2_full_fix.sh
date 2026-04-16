#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🚀 STAGE 9.2 FULL ARCHITECTURE FIX"

# -----------------------------
# 1. BACKUP
# -----------------------------
cp "$FILE" "${FILE}.bak_stage9_$(date +%s)"

echo "📦 Backup created"

# -----------------------------
# 2. REPLACE STATE MODEL (CRITICAL FIX)
# -----------------------------
awk '
/global last_duty/ {skip=1; next}
/global last_command_time/ {next}
skip==1 && /function/ {skip=0}

{print}
' "$FILE" > tmp && mv tmp "$FILE"

# inject safe STATE dict at top after module/imports
awk '
/using Sockets/ {
    print
    print ""
    print "# ========================="
    print "# 🧠 STAGE 9 SAFE STATE"
    print "# ========================="
    print "const STATE = Dict("
    print "    :last_duty => 0.0,"
    print "    :last_command_time => time()"
    print ")"
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# -----------------------------
# 3. PATCH handle_client() (FULL REPLACE)
# -----------------------------
awk '
/function handle_client/ {skip=1; print; print "    global STATE"; next}

/end/ && skip==1 {
    print
    skip=0
    next
}

skip==1 {next}

{print}
' "$FILE" > tmp && mv tmp "$FILE"

cat >> "$FILE" << 'JULIA'

function handle_client(sock)
    global STATE

    println("🌐 Client connected")

    try
        while isopen(sock)
            msg = strip(readline(sock))

            try
                parts = split(msg)

                if length(parts) == 1
                    val = parse(Float64, parts[1])
                    STATE[:last_duty] = clamp(val, -0.2, 0.2)
                    STATE[:last_command_time] = time()

                    println("📥 CMD → duty = ", STATE[:last_duty])

                elseif parts[1] == "duty"
                    val = parse(Float64, parts[2])
                    STATE[:last_duty] = clamp(val, -0.2, 0.2)
                    STATE[:last_command_time] = time()

                    println("📥 CMD → duty = ", STATE[:last_duty])

                elseif parts[1] == "stop"
                    STATE[:last_duty] = 0.0
                    STATE[:last_command_time] = time()

                    println("🛑 STOP")

                else
                    println("⚠️ Unknown command: ", msg)
                end

            catch e
                println("⚠️ Parse error: ", msg, " | ", e)
            end
        end

    catch e
        println("❌ Client error: ", e)
    end

    println("🔌 Client disconnected")
    close(sock)
end

JULIA

# -----------------------------
# 4. PATCH MOTOR LOOP SAFETY
# -----------------------------
sed -i 's/last_duty/STATE[:last_duty]/g' "$FILE"

# -----------------------------
# 5. WATCHDOG FIX
# -----------------------------
sed -i 's/2.0/5.0/g' "$FILE"

# -----------------------------
# 6. DEBUG INJECTION
# -----------------------------
echo "println(\"📡 VESC DUTY CALL DEBUG: \", STATE[:last_duty])" >> "$FILE"

echo "✅ STAGE 9.2 FIX COMPLETE"
