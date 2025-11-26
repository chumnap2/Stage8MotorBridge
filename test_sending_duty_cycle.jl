using PyCall

serial = pyimport("serial")
port = serial.Serial("/dev/ttyACM1", 115200)

# Then send pyvesc packets manually
pyvesc = pyimport("pyvesc")
SetDutyCycle = pyvesc.SetDutyCycle
#pip install --upgrade git+https://github.com/LiamBindle/pyvesc.git


