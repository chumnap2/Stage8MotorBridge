Stage8MotorBridge

Stage8MotorBridge provides simulation and control of a motor using Julia and Python. It supports both simulated motors and real hardware via a Motor Hardware Abstraction Layer (HAL).

Components

SimMotorController.jl – Julia simulation of the motor controller and motor bridge.

MotorHAL.jl – Hardware abstraction for real motor control (PWM/encoder interface).

fprime_motor_client.py – Python client to interface with the Julia simulation or real motor hardware.

pyvesc_working/ – Local copy of the PyVESC library, patched for Python 3.12.

Getting Started
Requirements

Julia ≥ 1.9

Python ≥ 3.10

Python packages: socket, json, time (installed in requirements.txt)

Julia packages: Plots, LibSerialPort (for hardware)

Running the Simulation

Simulation scripts are in SimMotorController.jl. Users can:

Enable the motor

Set speed

Run the simulation for a desired time

Generate plots for analysis

Interactive control can be done via fprime_motor_client.py, which connects to the simulation server, sends commands, and prints telemetry.

Hardware Integration

Ensure your motor is connected (e.g., /dev/ttyUSB0).

Implement hardware-specific functions in MotorHAL.jl:

set_motor_hardware_speed

read_motor_position

read_motor_velocity

Commands in Julia (CmdEnable!, CmdSpeed!, sendFeedback) operate the real motor similar to simulation.

Telemetry messages are printed as POS:<position>, VEL:<velocity>.

Safety checks and ramping are handled in MotorHAL.update!.

Python Client

fprime_motor_client.py connects to simulation or real hardware.

telemetry_reader_autoreconnect*.py scripts provide telemetry logging with automatic reconnect.

All scripts require the virtual environment to be activated.

Note: Use the local PyVESC library; do not install PyVESC via pip in the same environment, as it may conflict with the project’s local clone.

Virtual Environment Setup

Activate your Python virtual environment before running any scripts.

All required Python packages are listed in requirements.txt.

Julia packages must be installed for simulation or hardware interface.

Plots

Simulation and motor scripts generate plots in the plots/ folder, which can be opened with standard image viewers or previewed in Julia/Pluto notebooks.

(fprime-venv) chumnap@chumnap-OptiPlex-9020:~/fprime/Stage8MotorBridge$ export PYTHONPATH=$PWD/pyvesc_working
python3 telemetry_reader_autoreconnect_fixed.py
2025-11-14 20:23:46 [INFO] Serial port opened successfully.
2025-11-14 20:23:46 [INFO] Starting safe motor spin ramp...
2025-11-14 20:23:50 [INFO] Spin complete. Stopping motor...
Exception in thread Thread-1 (_heartbeat_cmd_func):
Traceback (most recent call last):
  File "/usr/lib/python3.12/threading.py", line 1073, in _bootstrap_inner
    self.run()
  File "/usr/lib/python3.12/threading.py", line 1010, in run
    self._target(*self._args, **self._kwargs)
  File "/home/chumnap/fprime/Stage8MotorBridge/pyvesc_working/pyvesc/VESC/VESC.py", line 65, in _heartbeat_cmd_func
    self.write(i)
  File "/home/chumnap/fprime/Stage8MotorBridge/pyvesc_working/pyvesc/VESC/VESC.py", line 96, in write
    self.serial_port.write(data)
  File "/home/chumnap/fprime-venv/lib/python3.12/site-packages/serial/serialposix.py", line 615, in write
    raise PortNotOpenError()
serial.serialutil.PortNotOpenError: Attempting to use a port that is not open
2025-11-14 20:23:52 [ERROR] Error opening serial port: invalid literal for int() with base 10: 'None'
2025-11-14 20:23:52 [INFO] Reconnect in 2s...
2025-11-14 20:23:54 [ERROR] Error opening serial port: invalid literal for int() with base 10: 'None'
2025-11-14 20:23:54 [INFO] Reconnect in 2s...
2025-11-14 20:23:56 [ERROR] Error opening serial port: invalid literal for int() with base 10: 'None'
2025-11-14 20:23:56 [INFO] Reconnect in 2s...
2025-11-14 20:23:58 [INFO] Serial port opened successfully.
2025-11-14 20:23:58 [INFO] Starting safe motor spin ramp...
2025-11-14 20:24:02 [INFO] Spin complete. Stopping motor...
Exception in thread Thread-5 (_heartbeat_cmd_func):
(fprime-venv) chumnap@chumnap-OptiPlex-9020:~/fprime/Stage8MotorBridge$ mpv motor_response_makie.png
 (+) Video --vid=1 (png 1600x1000 1.000fps)
VO: [gpu] 1600x1000 rgba
Exiting... (End of file)
(fprime-venv) chumnap@chumnap-OptiPlex-9020:~/fprime/Stage8MotorBridge$ 


License

MIT License
