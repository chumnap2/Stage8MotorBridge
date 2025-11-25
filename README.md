# Stage8MotorBridge

Minimal VESC motor bridge using **Julia + Python** with TCP client-server control.  
Fully automated setup and motor control with a **single command**.

---

## Features

- Control VESC motor via Python client  
- Julia server handles serial communication  
- One-command setup and run (`setup_and_run.sh`)  
- Fully contained Python venv and local pyvesc module  
- Tested for Python 3.11 and Julia 1.10  

---

## Quick Start

1. **Clone the repository**

```bash
git clone https://github.com/chumnap2/Stage8MotorBridge.git
cd Stage8MotorBridge
2Run the full setup, server, and client in one command
chmod +x setup_and_run.sh
./setup_and_run.sh
This will:

Create or activate the Python virtual environment (fprime-venv)

Install Python dependencies (crccheck, pyserial)

Configure Julia packages and PyCall

Start MotorBridgeServer.jl

Launch the Python client automatically
Using the Motor Client

Once the client starts, you can send motor commands:
> enable      # Enable motor
> duty 0.3    # Set duty cycle (0.0 to 1.0)
> stop        # Stop the motor
Notes

Use Ctrl+C to stop the Julia server or close the client terminal

Ensure the motor is safely mounted before sending commands

The server listens on TCP 127.0.0.1:5555 by default

Release v1.2

Fully automated setup_and_run.sh

Frozen Python dependencies in requirements.txt

Verified motor spin via client commands

Updated README with one-command instructions
