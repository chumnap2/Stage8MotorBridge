#!/bin/bash

# Base directory for the component
BASE_DIR=~/fprime/FPrimeMotorBridge/Components/MotorBridgeComponent

# Create folder structure
mkdir -p $BASE_DIR/include/Components
mkdir -p $BASE_DIR/src/Components

# Create header: include/Components/MotorBridgeComponentAc.hpp
cat > $BASE_DIR/include/Components/MotorBridgeComponentAc.hpp << 'EOF'
#ifndef MOTORBRIDGECOMPONENTAC_HPP
#define MOTORBRIDGECOMPONENTAC_HPP

#include "Fw/Types/BasicTypes.hpp"
#include "Fw/Comp/ActiveComponentBase.hpp"
#include "Fw/Port/InputPort.hpp"
#include "Fw/Port/OutputPort.hpp"

namespace Components {

class MotorBridgeComponent : public Fw::ActiveComponentBase {
public:
    MotorBridgeComponent(const char* compName);

    // Command handler
    void cmdIn_handler(const FwOpcodeType opCode, const U32 cmdSeq);

    // Output log function
    void logOut_text(const char* msg);

    // Expose ports for topology
    Fw::InputPort<FwOpcodeType, U32> cmdIn;
    Fw::OutputPort<const char*> statusOut;
};

} // namespace Components

#endif // MOTORBRIDGECOMPONENTAC_HPP
EOF

# Create source: src/Components/MotorBridgeComponentAc.cpp
cat > $BASE_DIR/src/Components/MotorBridgeComponentAc.cpp << 'EOF'
#include "Components/MotorBridgeComponentAc.hpp"
#include <cstdio>

namespace Components {

MotorBridgeComponent::MotorBridgeComponent(const char* compName)
: Fw::ActiveComponentBase(compName),
  cmdIn(),
  statusOut()
{
    // Bind input port to handler
    cmdIn.setObj(this);
    cmdIn.setHandler(&MotorBridgeComponent::cmdIn_handler);
}

void MotorBridgeComponent::cmdIn_handler(const FwOpcodeType opCode, const U32 cmdSeq) {
    printf("MotorBridge received command: opcode=%u seq=%u\n", opCode, cmdSeq);
    logOut_text("MotorBridge command processed");
}

void MotorBridgeComponent::logOut_text(const char* msg) {
    // Send string to output port
    statusOut.invoke(msg);
}

} // namespace Components
EOF

echo "Stage 8 MotorBridge C++ component created at $BASE_DIR"
