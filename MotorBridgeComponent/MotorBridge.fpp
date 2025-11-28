module Stage8 {

  active component MotorBridge {

    # --------------------
    # Commands
    # --------------------
    command SetDuty(duty: F32) opcode 0x01
    command Enable() opcode 0x02
    command Disable() opcode 0x03

    # --------------------
    # Telemetry Channels
    # --------------------
    telemetry CurrentDuty: F32 id 0x10
    telemetry CurrentRPM: F32 id 0x11
    telemetry ErrorCode: U32 id 0x12

    # --------------------
    # Events
    # --------------------
    event MotorEnabled severity activity low id 0x20 format "Motor enabled"
    event MotorDisabled severity activity low id 0x21 format "Motor disabled"
    event DutyUpdated severity activity high id 0x22 format "Duty set to {}" with duty: F32

  }

}
