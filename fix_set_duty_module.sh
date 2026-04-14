#!/bin/bash
set -e

FILE="VESCDriver.jl"

echo "🔧 Fixing set_duty inside module..."

# backup
cp "$FILE" "${FILE}.bak_fixmodule"
echo "📦 Backup created"

# remove any existing set_duty
sed -i '/function set_duty/,/^end/d' "$FILE"

# insert BEFORE end of module
awk '
/^end[[:space:]]*# module/ {
    print ""

    print "function set_duty(vesc, duty::Float64)"
    print "    try"
    print "        duty = clamp(duty, -0.3, 0.3)"
    print ""
    print "        scaled = Int32(round(duty * 100000))"
    print ""
    print "        payload = UInt8["
    print "            0x05,"
    print "            (scaled >> 24) & 0xFF,"
    print "            (scaled >> 16) & 0xFF,"
    print "            (scaled >> 8) & 0xFF,"
    print "            scaled & 0xFF"
    print "        ]"
    print ""
    print "        packet = UInt8[]"
    print "        push!(packet, 0x02)"
    print "        push!(packet, length(payload))"
    print "        append!(packet, payload)"
    print "        push!(packet, 0x00)"
    print "        push!(packet, 0x03)"
    print ""
    print "        write(vesc.port, packet)"
    print "        flush(vesc.port)"
    print ""
    print "    catch e"
    print "        println(\"❌ set_duty error: \", e)"
    print "    end"
    print "end"
    print ""

    print
    next
}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

# ensure export exists
grep -q "export set_duty" "$FILE" || \
sed -i 's/export /export set_duty, /' "$FILE"

echo "🔍 Verifying..."

grep -q "function set_duty" "$FILE" && echo "✅ set_duty present"
grep -q "export set_duty" "$FILE" && echo "✅ exported"

echo "🎉 FIX COMPLETE"
