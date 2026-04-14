register_fprime_module(
    SOURCES
        "${CMAKE_CURRENT_LIST_DIR}/TopologyComponentAi.xml"
)

fprime_add_library(Stage8MotorBridge_Topology
    SOURCES
        MotorBridgeTopologyApp.cpp
)
add_executable(MotorBridgeRun
    MotorBridgeRun.cpp
)
# Link against F Prime core libraries
target_link_libraries(MotorBridgeRun
    PRIVATE
        Stage8MotorBridge_Topology
        Fw_Types
        Fw_Comp
        Fw_Com
)

# Ensure it 
