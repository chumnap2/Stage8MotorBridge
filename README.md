Stage8/9 MotorBridge — Julia / PyVESC VESC Motor Bridge

This repository provides a hardware control bridge using Julia and PyVESC to control a VESC-driven motor. Stage9 adds ramped duty control, safe medium-motor limits, and TCP-based client control.

🧰 Requirements

Python 3.11+ (or compatible)

pyvesc and pyserial installed in a Python virtual environment

Julia 1.10+ + PyCall

A VESC connected via USB (e.g., /dev/ttyACM0) with correct permissions

⚙️ Setup Instructions
# 1. Create and activate Python venv
python3 -m venv fprime-venv-py311
source fprime-venv-py311/bin/activate

# 2. Install required Python packages
pip install pyvesc pyserial

# 3. Install and configure Julia packages
julia -e '
using Pkg
Pkg.activate(".")
Pkg.instantiate()
ENV["PYTHON"]="'$PWD'/fprime-venv-py311/bin/python"
Pkg.build("PyCall")
'
🚀 Running Stage9 MotorBridge
1. Start Julia Server
julia Stage9_MotorBridge.jl
TCP server listens on 127.0.0.1:12345

Ramp loop runs automatically, motor ramps smoothly when enabled

2. Run Python Client
python3 motor_client_stage9.py
Commands:

enable → enable motor

disable → disable motor

duty 0.0-0.4 → set motor duty (medium motor safe max 0.4)

stop → disable motor and exit

⚡ Safety Notes

Ramp loop ensures smooth acceleration/deceleration

Max duty for medium motor: 0.4

Always start motor disabled, then enable + duty

📦 Repository Layout
Stage8MotorBridge/
├── src/                  # main Julia code
│   └── Stage9_MotorBridge.jl
├── test/                 # small test scripts
│   └── vesc_test.jl
├── fprime-venv-py311/    # Python venv
├── motor_client_stage9.py # TCP client
├── requirements.txt
├── README.md
├── .gitignore

