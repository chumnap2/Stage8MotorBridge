#ifndef MOTORBRIDGE_HPP
#define MOTORBRIDGE_HPP

#include "MotorBridgeCfg.hpp"
#include "Fw/Types/BasicTypes.hpp"
#include "Fw/Com/ComBuffer.hpp"
#include "Fw/Com/Port/CmdPort.hpp"
#include "Fw/Com/Port/LogTextPort.hpp"
#include "Fw/Comp/ActiveComponentBase.hpp"

class MotorBridge : public Fw::ActiveComponentBase {
public:
    MotorBridge(const char* compName);
    ~MotorBridge();

    void init(void);

    // Command handler
    void CmdIn_handler(const Fw::CmdPacket& cmd);

    // Run loop for motor control
    void runLoop();

    // Logging helper
    void Log(const Fw::String& message);

private:
    U32 currentSpeed;
    int adcFeedback;
};

#endif // MOTORBRIDGE_HPP
