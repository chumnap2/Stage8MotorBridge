using PyCall

@pyimport serial
@pyimport pyvesc

ser = serial.Serial("/dev/ttyACM0", 115200)

function set_duty(duty::Float64)
    duty = clamp(duty, 0.0, 1.0)
    duty_int = Int(round(duty * 100000))

    cmd = pyvesc.SetDutyCycle(duty_int)
    packet = pyvesc.encode(cmd)

    ser.write(Vector{UInt8}(packet))
    println("[Julia] >>> VESC DUTY SENT: $duty")
end
