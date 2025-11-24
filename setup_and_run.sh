#!/bin/bash
# Stage8MotorBridge full setup and run script
# Run from project root

echo "🚀 Starting full Stage8MotorBridge setup..."

# --- Step 1: Python virtual environment ---
if [ ! -d "fprime-venv" ]; then
    echo "🐍 Creating Python venv..."
    python3 -m venv fprime-venv
else
    echo "🐍 Python venv already exists."
fi

echo "Activating Python venv..."
source fprime-venv/bin/activate

# --- Step 2: Install Python dependencies (excluding local pyvesc) ---
if [ -f requirements.txt ]; then
    echo "Installing Python packages..."
    pip install --upgrade pip
    # install only real dependencies, skip local pyvesc
    grep -v "pyvesc" requirements.txt | xargs -n 1 pip install
else
    echo "⚠️ requirements.txt not found, skipping Python package installation."
fi

# --- Step 3: Julia environment ---
echo "📦 Setting up Julia packages..."
julia -e '
using Pkg
Pkg.activate(".")
Pkg.instantiate()
'

# --- Step 4: Set PYTHONPATH for local Python modules ---
export PYTHONPATH="$PWD/pyvesc_working:$PWD"
echo "PYTHONPATH set to $PYTHONPATH"

# --- Step 5: Ensure PyCall uses correct Python ---
echo "Configuring PyCall to use Python venv..."
julia -e '
ENV["PYTHON"] = "'$PWD'/fprime-venv/bin/python"
using Pkg
Pkg.build("PyCall")
'

# --- Step 6: Start MotorBridgeServer in background ---
echo "Starting Julia MotorBridgeServer..."
julia MotorBridgeServer.jl &

# Give server a few seconds to start
sleep 2

# --- Step 7: Launch Python client ---
echo "Starting Python motor client..."
python3 "$PWD/motor_client.py"

# --- Done ---
echo "✅ Stage8MotorBridge setup and run complete!"
echo "Use Ctrl+C in the server terminal to stop the MotorBridgeServer."
