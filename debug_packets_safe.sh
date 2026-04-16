#!/bin/bash
FILE="VESCDriver.jl"

echo "🔧 Injecting safe packet debug..."

cp "$FILE" "${FILE}.bak_packet_debug"

# insert debug BEFORE write()
sed -i '/write(vesc.port, packet)/i println("📦 DUTY RAW=", duty); println("📦 SCALED=", scaled); println("📦 PACKET=", packet)' "$FILE"

echo "✅ Debug injected safely"
