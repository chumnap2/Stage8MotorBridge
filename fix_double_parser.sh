#!/bin/bash
set -e

FILE="MotorBridgeServer.jl"

echo "🔧 Removing duplicate parser (safe)..."

# backup
cp "$FILE" "${FILE}.bak_remove_double_parser"

awk '
BEGIN {skip=0}

/^\s*try\s*$/ && prev ~ /Unknown command/ {
    skip=1
    next
}

/^\s*catch/ && skip==1 {
    next
}

/^\s*end\s*$/ && skip==1 {
    skip=0
    next
}

{
    if (!skip) print
    prev=$0
}
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "✅ Duplicate parser removed"
