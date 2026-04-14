#include "Components/MotorBridge/MotorBridge.hpp"
#include <thread>

int main() {
    MotorBridge motor("MotorBridge");
    motor.init();

    // Start the motor loop in a thread
    std::thread loopThread(&MotorBridge::runLoop, &motor);

    // Simulate sending some commands
    for (int i = 0; i <= 100; i += 25) {
        Fw::CmdPacket cmd;
        cmd.setCmdID(i);  // encode speed as ID
        motor.CmdIn_handler(cmd);
        std::this_thread::sleep_for(std::chrono::seconds(3));
    }

    loopThread.join();
    return 0;
}
