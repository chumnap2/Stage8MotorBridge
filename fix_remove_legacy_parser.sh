#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Removing legacy parse(msg) block..."

cp "$FILE" "${FILE}.bak_legacy_parser"

awk '
BEGIN {skip=0}

/parsed = parse\(Float64, msg\)/ {
    skip=1
    next
}

/last_command_time = time\(\)/ && skip==1 {
    next
}

/println\("📥 CMD → duty/ && skip==1 {
    next
}

skip==1 {
    if ($0 ~ /^\s*$/) skip=0
    next
}

{print}
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "✅ Legacy parser removed"
