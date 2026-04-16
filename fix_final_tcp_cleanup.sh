#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Hard removing invalid input fallback..."

cp "$FILE" "${FILE}.bak_final_cleanup"

# delete the println line
sed -i '/Invalid input:/d' "$FILE"

# also remove orphan catch if any remains (safe guard)
sed -i '/catch/,+2d' "$FILE"

echo "✅ Cleanup complete"
