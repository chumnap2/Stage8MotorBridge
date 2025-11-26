# Stage8MotorBridge — Julia / pyvesc VESC Motor Bridge

This repository provides a hardware control bridge using Julia and pyvesc to control a VESC-driven motor. It supports serial communication over `/dev/ttyACM1`, safe duty-cycle control via Python packets, and can be extended into a TCP or F´-integrated bridge.

---

## 🧰 Requirements

- Python 3.11 (or compatible)  
- `pyvesc` and `pyserial` installed in a virtual environment  
- Julia 1.10 (or newer) + `PyCall` package  
- A VESC connected via USB (e.g. `/dev/ttyACM1`), with appropriate permissions  

---

## ⚙️ Setup Instructions

```bash
# 1. Create and activate Python virtual environment
python3 -m venv fprime-venv
source fprime-venv/bin/activate

# 2. Install required Python packages
pip install -r requirements.txt

# 3. In Julia, install PyCall if needed
julia -e 'using Pkg; Pkg.add("PyCall")'
🚀 Usage
Quick test (direct Julia control):
using PyCall
include("src/MotorBridgeServer.jl")   # or test/vesc_test.jl

# Example: spin motor at 20%
set_duty(0.2)
sleep(2)
set_duty(0.0)  # stop
Run full server (once implemented):
julia src/MotorBridgeServer.jl
Then send commands over TCP (or extend with your own control logic).
📦 Repository Layout
Stage8MotorBridge/
├── src/                # main Julia code
│   └── MotorBridgeServer.jl
├── test/               # small test scripts
│   └── vesc_test.jl
├── requirements.txt
├── README.md
├── .gitignore

