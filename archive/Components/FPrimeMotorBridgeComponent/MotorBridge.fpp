include "Fw/Types/Types.fpp"
include "Fw/Port/CmdPort.fpp"
include "Fw/Port/LogTextPort.fpp"

module Components {

    active component MotorBridge {
        input port cmdIn: Fw.CmdPort;
        output port statusOut: Fw.LogTextPort;
    };

    # Declare an instance (required)
    instance MotorBridge;
};
