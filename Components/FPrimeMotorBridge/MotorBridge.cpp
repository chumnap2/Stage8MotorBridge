#include "MotorBridge.hpp"
#include "Fw/Types/Assert.hpp"
#include <iostream>
#include <thread>
#include <chrono>

MotorBridge::MotorBridge(const char* compName)
    : Fw::ActiveComponentBase(compName),
      currentSpeed(0),
      adcFeedback(0)
{
}

MotorBridge::~MotorBridge() {}

void MotorBridge::init(void) {
    Fw::ActiveComponentBase::init();
    this->Log("MotorBridge initialized");
}

// Command handler: set motor speed 0–100%
void MotorBridge::CmdIn_handler(const Fw::CmdPacket& cmd) {
    U32 cmdId = cmd.getCmdID();
    U32 speed = cmdId % 101; // simulate speed encoded in command ID

    this->currentSpeed = speed;
    Fw::String logMsg;
    logMsg.format("CMD: Set motor speed to %u%%", speed);
    this->Log(logMsg);
}

// Periodic run loop: simulate motor control and ADC feedback
void MotorBridge::runLoop() {
    while (true) {
        // Simulate ADC feedback = speed ± noise
        adcFeedback = currentSpeed + (rand() % 5 - 2);

        Fw::String msg;
        msg.format("Motor speed: %u%% | ADC feedback: %d", currentSpeed, adcFeedback);
        this->Log(msg);

        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

// Log helper
void MotorBridge::Log(const Fw::String& message) {
    if (this->LogOut.isConnected()) {
        this->LogOut.send(message);
    }
    std::cout << message.toChar() << std::endl;
}
