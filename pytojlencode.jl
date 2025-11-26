#run in repl
using PyCall

serial = pyimport("serial")
pyvesc = pyimport("pyvesc")

SetDutyCycle = pyvesc.messages.setters.SetDutyCycle
encode = pyvesc.encode

# Open serial port
port = serial.Serial("/dev/ttyACM1", 115200)

function set_duty(d::Float64)
    # clamp to -1.0..1.0 and convert to VESC integer units
    vesc_duty = Int(round(clamp(d, -1.0, 1.0) * 100000))  # integer required!
    
    msg = SetDutyCycle(vesc_duty)      # pass integer
    packet = encode(msg)               # returns Python bytes
    
    # send raw bytes
    pycall(port.write, PyObject, packet)
end
