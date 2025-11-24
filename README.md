Stage8MotorBridge

This project controls a VESC motor via a Julia TCP server and a Python client.
It uses local, custom modules:

pyvesc_working/ → custom tested pyvesc version

F′ Stage8 components → local NASA F′ modules

Do NOT replace with public pyvesc or F′ modules, they may break compatibility.

Setup

Activate Python virtual environment: source fprime-venv/bin/activate

Set PYTHONPATH to include local pyvesc: export PYTHONPATH=$PWD/pyvesc_working

Start the Julia motor server: julia MotorBridgeServer.jl

Start the Python client: python motor_client.py

Commands available in the client

enable

set_speed <value> (0.0 to 1.0)

disable

exit

Testing the Motor

After launching both the server and client, you can test motor control in Python:

Connect to the VESC using pyvesc.VESC

Spin at 10% duty cycle, wait 2 seconds

Stop motor

This ensures the hardware is responding before running full scripts.

Notes

All previous experiments are stored in archive/

VERSION file contains the current project version

Safe ramping is implemented for smooth motor startup
