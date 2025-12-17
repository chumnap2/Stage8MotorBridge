#!/bin/bash
# setup_and_run_stage9.sh — Full Stage9 MotorBridge setup & run
# Run from project root
# Ensures pyvesc + PyCall work correctly with Julia

echo "🚀 Starting Stage9 MotorBridge setup..."

# --- Step 1: Python virtual environment ---
VENV_DIR="fprime-venv-py311"
PYTHON_BIN="$PWD/$VENV_DIR/bin/python"

if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating Python 3.11 venv..."
    python3.11 -m venv "$VENV_DIR"
else
    echo "🐍 Python venv already exists."
fi

echo "Activating Python venv..."
source "$VENV_DIR/bin/activate"

# --- Step 2: Upgrade pip/setuptools/wheel ---
echo "🔧 Upgrading pip, setuptools, wheel..."
pip install --upgrade pip setuptools wheel

# --- Step 3: Install Python dependencies ---
echo "📦 Installing Python packages..."
pip install pyvesc pyserial

# --- Step 4: Test Python imports ---
echo "🧪 Testing Python imports..."
python -c "import pyvesc; import serial; print('Python OK ✅')"

# --- Step 5: Julia environment ---
echo "📦 Setting up Julia packages..."
julia -e '
using Pkg
Pkg.activate(".")
Pkg.instantiate()
'

# --- Step 6: Configure PyCall to use Python venv ---
echo "🔗 Configuring PyCall to use Python venv..."
julia -e '
ENV["PYTHON"] = "'$PYTHON_BIN'"
using Pkg
Pkg.build("PyCall")
using PyCall
pyimport("pyvesc")
println("PyCall + pyvesc OK ✅")
'

# --- Step 7: Kill any existing servers/clients ---
echo "🛑 Killing old MotorBridge processes..."
pkill -f Stage9_MotorBridge.jl || true
pkill -f motor_client_stage9.py || true
sleep 1

# --- Step 8: Start Stage9 Julia MotorBridgeServer in background ---
echo "🚦 Starting Julia Stage9 MotorBridgeServer..."
julia Stage9_MotorBridge.jl &

# Give server a few seconds to start
sleep 2

# --- Step 9: Launch Python motor client ---
echo "🚗 Starting Python motor client..."
python3 "$PWD/motor_client_stage9.py"

# --- Done ---
echo "✅ Stage9 MotorBridge setup and run complete!"
echo "Use Ctrl+C in the server terminal to stop the MotorBridgeServer."
