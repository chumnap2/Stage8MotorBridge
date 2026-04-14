# MotorBridgeTopology.fpp
topology MotorBridgeTopology {

    # Instantiate the MotorBridge component
    component MotorBridge motorBridge;

    # Example command driver component
    component CmdDriver cmdDriver;

    # Example logger component
    component Logger logger;

    # Connect the command output from driver to MotorBridge input
    connect cmdDriver.CmdOut -> motorBridge.CmdIn;

    # Connect the MotorBridge log output to the Logger input
    connect motorBridge.LogOut -> logger.LogIn;
}
