# Stage8MotorBridge

Simulation and control of a motor via Julia and Python clients. Supports both simulated motors and real hardware through a Motor Hardware Abstraction Layer (HAL).

## Components

- `SimMotorController.jl` – Julia simulation of MotorController and MotorBridge.
- `MotorHAL.jl` – Hardware abstraction for real motor control (PWM/encoder interface).
- `fprime_motor_client.py` – Python client to interface with Julia simulation or hardware.

## Getting Started

### Requirements

- Julia >= 1.9
- Python >= 3.10
- Packages:
  - Julia: `Plots`, `LibSerialPort` (for hardware)
  - Python: `socket`, `json`, `time`

### Running the Simulation

```julia
using Plots
include("SimMotorController.jl")

# Enable motor
CmdEnable!(mb, true)
CmdSpeed!(mb, 5.0)

# Run simulation for 10 seconds
simulate!(10.0)

# Plot results
plot_results()

Interactive Control via Python
from fprime_motor_client import FprimeMotorClient
import time

client = FprimeMotorClient()
client.connect()        # default port 9000
client.enable_motor()
client.set_speed(5.0)

try:
    client.run()        # prints telemetry; Ctrl+C to stop
except KeyboardInterrupt:
    client.disable_motor()
Hardware Integration

Ensure your motor is connected (e.g., /dev/ttyUSB0).

Edit MotorHAL.jl to implement set_motor_hardware_speed, read_motor_position, and read_motor_velocity.

Use the same Julia commands as in simulation (CmdEnable!, CmdSpeed!, sendFeedback) to operate real hardware.

Notes

Telemetry messages are printed as POS:<position>, VEL:<velocity>.

step_motor(speed) can be used for interactive speed changes in Julia.

For real hardware, ramping and safety checks are handled in MotorHAL.update!.

License

MIT License
