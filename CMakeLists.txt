cmake_minimum_required(VERSION 3.13)
project(Stage8MotorBridge CXX)

include("${FPRIME_FRAMEWORK_PATH}/cmake/FPrime.cmake")

fprime_initialize_build_system()

add_fprime_subdirectory("Components")
add_fprime_subdirectory("Deployments")

set(FPRIME_INSTALL_DIR "${CMAKE_CURRENT_LIST_DIR}/build-artifacts")
