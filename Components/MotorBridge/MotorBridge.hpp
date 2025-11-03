#ifndef STAGE8_MOTOR_BRIDGE_HPP
#define STAGE8_MOTOR_BRIDGE_HPP

#include "MotorBridgeComponentAc.hpp"

namespace Stage8 {

class MotorBridge : public MotorBridgeComponentBase {
  public:
    explicit MotorBridge(const char* compName);
    void init();
    void handleCmd(int arg);
};

} // namespace Stage8

#endif
