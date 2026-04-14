include "Fw/Types.fpp"
include "Fw/Port/CmdPort.fpp"
include "Fw/Port/LogTextPort.fpp"

module Components {

  active component MotorBridge {

    async input port cmdIn: Fw::CmdPort
    async output port statusOut: Fw::LogTextPort

  }

}
