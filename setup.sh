#!/bin/bash
# setup.sh - One-command setup and launch for Stage8MotorBridge

# Activate Python virtual environment
echo "Activating Python virtual environment..."
source fprime-venv/bin/activate

# Set PYTHONPATH for local pyvesc
export PYTHONPATH=$PWD/pyvesc_working
echo "PYTHONPATH set to $PYTHONPATH"

# Start Julia motor server in background
echo "Starting Julia MotorBridgeServer..."
julia MotorBridgeServer.jl &

# Give server a few seconds to start
sleep 2

# Launch Python client
echo "Starting Python motor client..."
python motor_client.py

# Notes for user
echo "To stop the server, press Ctrl+C in the terminal running this script or use the client 'disable' command."
