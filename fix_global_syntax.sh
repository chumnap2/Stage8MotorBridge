#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Fixing Julia module globals..."

cp "$FILE" "${FILE}.bak_global_fix"

# remove ONLY leading 'global ' at start of line
sed -i 's/^global //g' "$FILE"

echo "✅ Global syntax fixed"
