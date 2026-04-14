Stage 8 MotorBridge Contract

ENTRYPOINT:
  MotorBridgeServer.jl

DRIVER:
  VESCDriver.jl

COMMANDS:
  duty <float>   [-0.1, 0.1]
  stop
  ping

REAL-TIME LOOP:
  20 Hz motor heartbeat

TRANSPORT:
  TCP 127.0.0.1:5555

RULE:
  No other file is allowed to control hardware
