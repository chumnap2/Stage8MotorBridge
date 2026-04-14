#!/bin/bash

# Set base path
BASE_DIR=~/fprime/Stage8MotorBridge/Components/MotorBridgeComponent

# Create folder structure
mkdir -p $BASE_DIR/fpp
mkdir -p $BASE_DIR/include/Components
mkdir -p $BASE_DIR/src/Components

# Create fpp/MotorBridge.fpp
cat > $BASE_DIR/fpp/MotorBridge.fpp << 'EOF'
include "Fw/Types/Types.fpp"
include "Fw/Port/CmdPort.fpp"
include "Fw/Port/LogTextPort.fpp"

module Components {
    active component MotorBridge {
        input port cmdIn: Fw.CmdPort;
        output port statusOut: Fw.LogTextPort;
    };
    instance MotorBridge;
};
EOF

# Create include/Components/MotorBridgeComponentAc.hpp
cat > $BASE_DIR/include/Components/MotorBridgeComponentAc.hpp << 'EOF'
#ifndef MOTORBRIDGECOMPONENTAC_HPP
#define MOTORBRIDGECOMPONENTAC_HPP

#include "Fw/Types/BasicTypes.hpp"
#include "Fw/Com/ComPacket.hpp"
#include "Fw/Port/InputPort.hpp"
#include "Fw/Port/OutputPort.hpp"
#include "Fw/Comp/ActiveComponentBase.hpp"

namespace Components {

class MotorBridgeComponent : public Fw::ActiveComponentBase {
public:
    MotorBridgeComponent(const char* compName);

    void cmdIn_handler(const FwOpcodeType opCode, const U32 cmdSeq);

private:
    void logOut_text(const char* msg);
};

} // namespace Components

#endif // MOTORBRIDGECOMPONENTAC_HPP
EOF

# Create src/Components/MotorBridgeComponentAc.cpp
cat > $BASE_DIR/src/Components/MotorBridgeComponentAc.cpp << 'EOF'
#include "Components/MotorBridgeComponentAc.hpp"
#include "Fw/Logger/Logger.hpp"
#include <cstdio>

namespace Components {

MotorBridgeComponent::MotorBridgeComponent(const char* compName)
: Fw::ActiveComponentBase(compName) {}

void MotorBridgeComponent::cmdIn_handler(const FwOpcodeType opCode, const U32 cmdSeq) {
    this->logOut_text("MotorBridge command received");
}

void MotorBridgeComponent::logOut_text(const char* msg) {
    // This will send a log through the statusOut port
    // Replace with actual logging mechanism in Stage 8
    printf("%s\n", msg);
}

} // namespace Components
EOF

echo "MotorBridge Stage 8 component structure created at $BASE_DIR"
