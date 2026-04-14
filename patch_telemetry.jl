filename = "main.jl"  # <-- change if needed

code = read(filename, String)

# --- Replace telemetry_loop ---
new_telemetry = """
function telemetry_loop()
    println("📡 Telemetry loop running (5 Hz)")

    global vesc, last_rpm, last_current, last_voltage

    while true
        try
            if vesc !== nothing

                v = VESCDriver.get_mc_values(vesc)

                last_rpm = hasproperty(v, :rpm) ? v.rpm : 0.0
                last_current = hasproperty(v, :current_motor) ? v.current_motor : 0.0
                last_voltage = hasproperty(v, :v_in) ? v.v_in : 0.0

                println("📊 RPM=\$(last_rpm) | I=\$(last_current) | V=\$(last_voltage)")
            end
        catch e
            println("❌ Telemetry error: ", e)
        end

        sleep(0.2)
    end
end
"""

# Replace existing telemetry_loop (simple pattern)
code = replace(code, r"function telemetry_loop\([\s\S]*?end" => new_telemetry)

# --- Ensure telemetry_loop is enabled ---
if !occursin("@async telemetry_loop()", code)
    code = replace(code,
        "@async motor_loop()" => "@async motor_loop()\n@async telemetry_loop()"
    )
end

# Write back
write(filename, code)

println("✅ Telemetry loop replaced and enabled successfully.")
