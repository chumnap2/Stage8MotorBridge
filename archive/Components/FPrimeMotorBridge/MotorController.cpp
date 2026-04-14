#include "MotorController.hpp"
#include <iostream>

namespace Stage8 {

void MotorController::setSpeed(float value) {
    std::cout << "[MotorController] Speed set to " << value << std::endl;
}

} // namespace Stage8
