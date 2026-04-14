# MotorBridge.fpp
component MotorBridge {

    # Import local port interfaces
    import "./CmdPort.fpp"
    import "./LogTextPort.fpp"

    # Input command port
    input CmdPort CmdIn;

    # Output log port
    output LogTextPort LogOut;

}
