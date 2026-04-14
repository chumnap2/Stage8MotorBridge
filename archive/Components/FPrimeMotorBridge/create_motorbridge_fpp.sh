#!/bin/bash

# Base folder for Stage8MotorBridge
BASE_DIR=~/fprime/Stage8MotorBridge

# Create folder structure
mkdir -p "$BASE_DIR/Components/MotorBridge"
mkdir -p "$BASE_DIR/Topologies"

# Create CmdPort.fpp
cat > "$BASE_DIR/Components/MotorBridge/CmdPort.fpp" <<'EOL'
# CmdPort.fpp
interface CmdPort {
    # Command input port carrying a command ID (U32)
    command U32 Cmd;
}
EOL

# Create LogTextPort.fpp
cat > "$BASE_DIR/Components/MotorBridge/LogTextPort.fpp" <<'EOL'
# LogTextPort.fpp
interface LogTextPort {
    # Log message output port carrying a string
    event String LogMessage;
}
EOL

# Create MotorBridge.fpp
cat > "$BASE_DIR/Components/MotorBridge/MotorBridge.fpp" <<'EOL'
# MotorBridge.fpp
component MotorBridge {

    # Import local port interfaces
    import "./CmdPort.fpp"
    import "./LogTextPort.fpp"

    # Input command port
    input CmdPort CmdIn;

    # Output log port
    output LogTextPort LogOut;

}
EOL

# Create MotorBridgeTopology.fpp
cat > "$BASE_DIR/Topologies/MotorBridgeTopology.fpp" <<'EOL'
# MotorBridgeTopology.fpp
topology MotorBridgeTopology {

    # Instantiate the MotorBridge component
    component MotorBridge motorBridge;

    # Example command driver component
    component CmdDriver cmdDriver;

    # Example logger component
    component Logger logger;

    # Connect the command output from driver to MotorBridge input
    connect cmdDriver.CmdOut -> motorBridge.CmdIn;

    # Connect the MotorBridge log output to the Logger input
    connect motorBridge.LogOut -> logger.LogIn;
}
EOL

echo "All FPP files created successfully in $BASE_DIR"

# Verify
ls -R "$BASE_DIR"
