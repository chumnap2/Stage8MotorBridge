#!/bin/bash

# Base directory for the test driver
BASE_DIR=~/fprime/Stage8MotorBridge/TestDriver
mkdir -p $BASE_DIR/src

# Create main.cpp
cat > $BASE_DIR/src/main.cpp << 'EOF'
#include "Components/MotorBridgeComponentAc.hpp"
#include <iostream>

int main() {
    // Instantiate the MotorBridge component
    Components::MotorBridgeComponent motorBridge("MotorBridge");

    // Simulate sending a command
    FwOpcodeType testOp = 1;
    U32 testSeq = 42;

    std::cout << "Sending test command to MotorBridge...\n";
    motorBridge.cmdIn.invoke(testOp, testSeq);

    return 0;
}
EOF

# Create a simple Makefile
cat > $BASE_DIR/Makefile << 'EOF'
CXX = g++
CXXFLAGS = -I../../Components/MotorBridgeComponent/include -std=c++17

SRC = src/main.cpp ../../Components/MotorBridgeComponent/src/Components/MotorBridgeComponentAc.cpp
OBJ = $(SRC:.cpp=.o)
TARGET = test_motorbridge

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET) $(OBJ)
EOF

echo "Stage 8 MotorBridge test driver created at $BASE_DIR"
echo "To build and run:"
echo "  cd $BASE_DIR"
echo "  make"
echo "  ./test_motorbridge"
