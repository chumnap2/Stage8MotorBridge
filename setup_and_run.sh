#!/bin/bash
# -------------------------------------------------------------------
# setup_and_run.sh
# Fully automated Stage 8: MotorBridge + F´ components + initial motor spin
# -------------------------------------------------------------------

set -e  # Exit on any error

echo "🚀 Stage 8 Setup & Run Starting..."

# -------------------------------------------------------------------
# 1️⃣ Activate Python virtual environment
# -------------------------------------------------------------------
VENV_DIR="fprime-venv-py311"

if [ -d "$VENV_DIR" ]; then
    echo "⚡ Activating Python virtual environment $VENV_DIR..."
    source "$VENV_DIR/bin/activate"
else
    echo "⚠️ Virtual environment $VENV_DIR not found! Please create it first."
    exit 1
fi

# -------------------------------------------------------------------
# 2️⃣ Ensure Julia packages are ready
# -------------------------------------------------------------------
echo "⚡ Instantiating Julia environment..."
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# -------------------------------------------------------------------
# 3️⃣ Export local repo for Python imports
# -------------------------------------------------------------------
export PYTHONPATH=$PWD:$PYTHONPATH
echo "⚡ PYTHONPATH set to include local repo"

# -------------------------------------------------------------------
# 4️⃣ Kill any previous MotorBridgeServer on port 5555
# -------------------------------------------------------------------
EXISTING_PID=$(lsof -ti :5555 || true)
if [ -n "$EXISTING_PID" ]; then
    echo "⚠️ Killing previous MotorBridgeServer2 process (PID=$EXISTING_PID)..."
    kill -9 $EXISTING_PID
fi

# -------------------------------------------------------------------
# 5️⃣ Launch MotorBridgeServer2.jl in background
# -------------------------------------------------------------------
echo "⚡ Launching MotorBridgeServer2.jl..."
nohup julia MotorBridgeServer2.jl > motorbridge_server.log 2>&1 &
MOTOR_PID=$!
echo "✅ MotorBridgeServer2 launched (PID=$MOTOR_PID)"

# Wait a moment to ensure server is listening
sleep 2

# -------------------------------------------------------------------
# 6️⃣ Send initial safe motor spin (2% duty)
# -------------------------------------------------------------------
echo "⚡ Sending initial safe duty=0.02 to MotorBridgeServer..."
echo "duty 0.02" | nc 127.0.0.1 5555
echo "✅ Initial spin command sent"

# -------------------------------------------------------------------
# 7️⃣ Launch F´ components
# -------------------------------------------------------------------
echo "⚡ Launching Stage 8 F´ components..."
nohup fprime-util run -c Components/FPrimeMotorBridgeComponent/ > fprime_components.log 2>&1 &
FPRIME_PID=$!
echo "✅ F´ components launched (PID=$FPRIME_PID)"

# -------------------------------------------------------------------
# 8️⃣ Trap Ctrl+C and exit for clean shutdown
# -------------------------------------------------------------------
cleanup() {
    echo "🛑 Shutdown requested, stopping Stage 8 processes..."
    kill $MOTOR_PID $FPRIME_PID 2>/dev/null || true
    wait $MOTOR_PID $FPRIME_PID 2>/dev/null || true
    echo "✅ Stage 8 shutdown complete."
    exit 0
}
trap cleanup SIGINT SIGTERM

# -------------------------------------------------------------------
# 9️⃣ Tail logs for monitoring
# -------------------------------------------------------------------
echo "🔍 Tailing MotorBridgeServer2 log. Ctrl+C to stop."
tail -f motorbridge_server.log
