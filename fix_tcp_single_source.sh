#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Removing fallback parser (final cleanup)..."

cp "$FILE" "${FILE}.bak_final_tcp"

awk '
BEGIN {skip=0}

/try/ && $0 ~ /parse\(Float64, msg\)/ {
    skip=1
    next
}

skip==1 {
    if ($0 ~ /catch/) {next}
    if ($0 ~ /end/) {skip=0; next}
    next
}

{print}
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "✅ Fallback parser removed"
