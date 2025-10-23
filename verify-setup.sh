#!/bin/bash
# Arduino DevContainer Environment Verification Script

echo "🔍 Arduino DevContainer Environment Check"
echo "========================================"

# Check Arduino CLI
echo "📱 Arduino CLI:"
if command -v arduino-cli &> /dev/null; then
    arduino-cli version
    echo "   ✅ Arduino CLI is installed"
else
    echo "   ❌ Arduino CLI not found"
    exit 1
fi

# Check Arduino cores
echo ""
echo "🔧 Arduino Cores:"
CORES=$(arduino-cli core list)
if [[ $CORES == *"arduino:avr"* ]]; then
    echo "   ✅ Arduino AVR core is installed"
    arduino-cli core list
else
    echo "   ❌ Arduino AVR core not found"
    exit 1
fi

# Check VS Code configuration
echo ""
echo "📝 VS Code Configuration:"
if [ -f ".vscode/c_cpp_properties.json" ]; then
    echo "   ✅ C++ IntelliSense configuration found"
else
    echo "   ❌ C++ IntelliSense configuration missing"
fi

if [ -f ".vscode/arduino.json" ]; then
    echo "   ✅ Arduino project configuration found"
else
    echo "   ❌ Arduino project configuration missing"
fi

# Test compilation
echo ""
echo "🔨 Compilation Test:"
# Read the board FQBN from arduino.json
BOARD_FQBN=$(jq -r '.board' .vscode/arduino.json 2>/dev/null || echo "arduino:avr:leonardo")
if arduino-cli compile --fqbn "$BOARD_FQBN" src/hello-world > /dev/null 2>&1; then
    echo "   ✅ Hello World sketch compiles successfully"
    # Get compilation stats
    COMPILE_OUTPUT=$(arduino-cli compile --fqbn "$BOARD_FQBN" src/hello-world 2>&1)
    echo "   📊 $(echo "$COMPILE_OUTPUT" | grep "Sketch uses")"
    GLOBAL_VARS=$(echo "$COMPILE_OUTPUT" | grep "Global variables" || echo "")
    if [ -n "$GLOBAL_VARS" ]; then
        echo "   📊 $GLOBAL_VARS"
    fi
else
    echo "   ❌ Compilation failed for board: $BOARD_FQBN"
    exit 1
fi

# Check Arduino.h availability
echo ""
echo "📚 Arduino Libraries:"
ARDUINO_H=$(find ~/.arduino15 -name "Arduino.h" -type f | head -1)
if [ -n "$ARDUINO_H" ]; then
    echo "   ✅ Arduino.h found at: $ARDUINO_H"
else
    echo "   ❌ Arduino.h not found"
    exit 1
fi

echo ""
echo "🎉 All checks passed! Your Arduino development environment is ready."
echo ""
echo "📋 Quick Commands:"
echo "   Compile: arduino-cli compile --fqbn $BOARD_FQBN src/hello-world"
echo "   Upload:  arduino-cli upload -p /dev/ttyUSB0 --fqbn $BOARD_FQBN src/hello-world"
echo "   Serial:  arduino-cli monitor -p /dev/ttyUSB0"
echo ""
echo "🎯 Configured for board: $BOARD_FQBN"