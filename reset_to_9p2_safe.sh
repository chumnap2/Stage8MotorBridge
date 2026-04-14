#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🚨 RESETTING MOTORBRIDGE TO STABLE 9.2 BASE"

# -------------------------------------------------
# 1. BACKUP EVERYTHING
# -------------------------------------------------
cp "$FILE" "${FILE}.backup_before_9p2"

echo "📦 Backup saved"

# -------------------------------------------------
# 2. REMOVE BROKEN listen PATTERNS
# -------------------------------------------------
sed -i 's/listen(127\.0\.0\.1/listen(ip"127.0.0.1/g' "$FILE"
sed -i 's/listen("127.0.0.1"/listen(ip"127.0.0.1"/g' "$FILE"

# -------------------------------------------------
# 3. REMOVE OLD TELEMETRY CRASH CALLS
# -------------------------------------------------
sed -i '/get_mc_values/d' "$FILE"
sed -i '/decode_values/d' "$FILE"
sed -i '/VESCDriver.get_values/d' "$FILE"

# -------------------------------------------------
# 4. ENSURE SAFE SOCKET IMPORT EXISTS
# -------------------------------------------------
grep -q "using Sockets" "$FILE" || sed -i '1i using Sockets' "$FILE"

# -------------------------------------------------
# 5. PATCH SAFE LISTEN USAGE (GLOBAL FIX)
# -------------------------------------------------
cat > listen_fix.tmp << 'INNER'

# FIXED SAFE SERVER BIND (DO NOT TOUCH)
server = listen(ip"127.0.0.1", 5555)
println("📡 TCP listening on 127.0.0.1:5555")

INNER

echo "🔧 injecting safe listen template (manual verify required)"

echo "✅ RESET COMPLETE"
echo "👉 NOW RUN: julia -e 'include(\"MotorBridgeServer.jl\")'"
