# Load the F´ CMake system
include("${CMAKE_CURRENT_LIST_DIR}/../../../fprime/cmake/FPrime.cmake")

# Define this as an F´ component
fprime_add_component(
    SOURCES
        Stage8MotorBridge.cpp
    HEADERS
        Stage8MotorBridge.hpp
    DEPENDS
        Fw/Types
        Fw/Obj
)
