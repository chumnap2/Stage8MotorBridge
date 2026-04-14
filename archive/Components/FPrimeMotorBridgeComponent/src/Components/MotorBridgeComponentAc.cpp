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
