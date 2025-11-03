#include "MotorBridge.hpp"
#include <Fw/Log/Log.hpp>

namespace Stage8 {

MotorBridge::MotorBridge(const char* compName) : MotorBridgeComponentBase(compName) {}

void MotorBridge::init() {}

void MotorBridge::handleCmd(int arg) {
    FW_LOG_INFO("MotorBridge received command arg=%d", arg);
}

} // namespace Stage8
