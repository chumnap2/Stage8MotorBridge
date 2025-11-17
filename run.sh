#!/bin/bash
# Stage8MotorBridge: Interactive Run Script
# Run this from ~/fprime/Stage8MotorBridge

echo "Activating Python virtual environment..."
source ~/fprime-venv/bin/activate

echo ""
echo "Select mode to run:"
echo "1) Real motor (Python client)"
echo "2) Motor simulation (Julia)"
read -p "Enter choice [1 or 2]: " choice

case $choice in
    1)
        echo "Running Python motor client..."
        python fprime_motor_client.py
        ;;
    2)
        echo "Running Julia motor simulation..."
        julia SimMotorController.jl
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
