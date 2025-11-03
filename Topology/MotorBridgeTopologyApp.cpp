#include "Components/MotorBridge/MotorBridge.hpp"

namespace Stage8 {

void setupTopology() {
    static MotorBridge motorBridge("motorBridge");
    motorBridge.init();
}

} // namespace Stage8
