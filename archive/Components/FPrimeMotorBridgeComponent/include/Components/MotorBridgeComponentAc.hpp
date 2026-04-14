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
