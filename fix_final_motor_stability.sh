#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Final motor stability fix..."

cp "$FILE" "${FILE}.bak_final_stable"

# 1. remove fallback parser safely
sed -i '/parse(Float64, msg)/d' "$FILE"
sed -i '/Invalid input:/d' "$FILE"

# 2. increase duty clamp range
sed -i 's/clamp(val, -0.2, 0.2)/clamp(val, -0.8, 0.8)/g' "$FILE"

echo "✅ Final fix applied"
