#!/bin/bash
set -e

echo "🔧 Setting up Arduino development environment..."

# Ensure Arduino CLI is available and update core index
arduino-cli core update-index

# List installed cores for debugging
echo "📦 Installed Arduino cores:"
arduino-cli core list

# Auto-detect connected Arduino boards
echo "🔍 Scanning for connected Arduino boards..."
BOARD_LIST=$(arduino-cli board list --format text)
echo "$BOARD_LIST"

# Extract board information from connected devices
DETECTED_PORT=""
DETECTED_FQBN=""
DETECTED_BOARD_NAME=""
DETECTED_CORE=""

# Parse board list output (skip header line)
while IFS= read -r line; do
    if [[ "$line" =~ ^/dev/ ]]; then
        # Extract fields: Port, Protocol, Type, Board Name, FQBN, Core
        DETECTED_PORT=$(echo "$line" | awk '{print $1}')
        # Extract board name (everything between "Type" and "FQBN")
        DETECTED_BOARD_NAME=$(echo "$line" | sed 's/^[^[:space:]]*[[:space:]]*[^[:space:]]*[[:space:]]*[^[:space:]]*[[:space:]]*//' | sed 's/[[:space:]]*[^[:space:]]*[[:space:]]*[^[:space:]]*$//')
        DETECTED_FQBN=$(echo "$line" | awk '{print $(NF-1)}')
        DETECTED_CORE=$(echo "$line" | awk '{print $NF}')
        
        echo "📱 Found connected board:"
        echo "   Port: $DETECTED_PORT"
        echo "   Board: $DETECTED_BOARD_NAME"
        echo "   FQBN: $DETECTED_FQBN"
        echo "   Core: $DETECTED_CORE"
        break  # Use the first detected board
    fi
done <<< "$BOARD_LIST"

# Auto-detect the primary platform (prefer detected board, fallback to installed cores)
INSTALLED_CORES=$(arduino-cli core list --format text | awk 'NR>1 {print $1}')
PRIMARY_PLATFORM=""
BOARD_FQBN=""
DEFINES=()
BOARD_NAME=""
ARDUINO_PORT="/dev/ttyUSB0"  # Default fallback

echo "🔍 Detected cores: $INSTALLED_CORES"

# If we detected a connected board, use it
if [ -n "$DETECTED_FQBN" ] && [ -n "$DETECTED_PORT" ]; then
    echo "🎯 Using detected board configuration"
    PRIMARY_PLATFORM="$DETECTED_CORE"
    BOARD_FQBN="$DETECTED_FQBN"
    BOARD_NAME="$DETECTED_BOARD_NAME"
    ARDUINO_PORT="$DETECTED_PORT"
else
    echo "⚠️  No connected board detected, using fallback configuration"
fi

# Configure platform-specific settings based on detected or fallback board
if [ -n "$DETECTED_FQBN" ]; then
    # Use detected board configuration
    case "$DETECTED_FQBN" in
        *"arduino:avr:uno"*)
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_AVR_UNO"
                "ARDUINO_ARCH_AVR"
                "__AVR_ATmega328P__"
                "F_CPU=16000000L"
            )
            ;;
        *"arduino:avr:leonardo"*)
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_AVR_LEONARDO"
                "ARDUINO_ARCH_AVR"
                "__AVR_ATmega32u4__"
                "F_CPU=16000000L"
            )
            ;;
        *"arduino:avr:nano"*)
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_AVR_NANO"
                "ARDUINO_ARCH_AVR"
                "__AVR_ATmega328P__"
                "F_CPU=16000000L"
            )
            ;;
        *"esp8266"*)
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_ESP8266_NODEMCU"
                "ARDUINO_ARCH_ESP8266"
                "ESP8266"
                "F_CPU=80000000L"
                "MMU_IRAM_SIZE=0x8000"
                "MMU_ICACHE_SIZE=0x8000"
            )
            ;;
        *"esp32"*)
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_NodeMCU_32S"
                "ARDUINO_ARCH_ESP32"
                "ESP32"
                "F_CPU=240000000L"
                "ARDUINO_USB_CDC_ON_BOOT=0"
            )
            ;;
        *)
            # Generic Arduino defines for unknown boards
            DEFINES=(
                "ARDUINO=10819"
                "ARDUINO_ARCH_AVR"
                "F_CPU=16000000L"
            )
            ;;
    esac
else
    # Fallback configuration based on installed cores
    for CORE in $INSTALLED_CORES; do
        case $CORE in
            "arduino:avr")
                if [ -z "$PRIMARY_PLATFORM" ]; then
                    PRIMARY_PLATFORM="arduino:avr"
                    BOARD_FQBN="arduino:avr:leonardo"
                    BOARD_NAME="Arduino Leonardo"
                    DEFINES=(
                        "ARDUINO=10819"
                        "ARDUINO_AVR_LEONARDO"
                        "ARDUINO_ARCH_AVR"
                        "__AVR_ATmega32u4__"
                        "F_CPU=16000000L"
                    )
                fi
                ;;
            "esp8266:esp8266")
                PRIMARY_PLATFORM="esp8266:esp8266"
                BOARD_FQBN="esp8266:esp8266:nodemcuv2"
                BOARD_NAME="NodeMCU 1.0 (ESP-12E Module)"
                DEFINES=(
                    "ARDUINO=10819"
                    "ARDUINO_ESP8266_NODEMCU"
                    "ARDUINO_ARCH_ESP8266"
                    "ESP8266"
                    "F_CPU=80000000L"
                    "MMU_IRAM_SIZE=0x8000"
                    "MMU_ICACHE_SIZE=0x8000"
                )
                break  # Prefer ESP8266 over Arduino AVR if both are available
                ;;
            "esp32:esp32")
                PRIMARY_PLATFORM="esp32:esp32"
                BOARD_FQBN="esp32:esp32:nodemcu-32s"
                BOARD_NAME="NodeMCU-32S"
                DEFINES=(
                    "ARDUINO=10819"
                    "ARDUINO_NodeMCU_32S"
                    "ARDUINO_ARCH_ESP32"
                    "ESP32"
                    "F_CPU=240000000L"
                    "ARDUINO_USB_CDC_ON_BOOT=0"
                )
                break  # Prefer ESP32 over others if available
                ;;
        esac
    done
fi

# Fallback to Arduino AVR if no platform detected
if [ -z "$PRIMARY_PLATFORM" ]; then
    echo "⚠️  No recognized Arduino cores found, installing Arduino AVR as fallback..."
    arduino-cli core install arduino:avr
    PRIMARY_PLATFORM="arduino:avr"
    BOARD_FQBN="arduino:avr:leonardo"
    BOARD_NAME="Arduino Leonardo"
    DEFINES=(
        "ARDUINO=10819"
        "ARDUINO_AVR_LEONARDO"
        "ARDUINO_ARCH_AVR"
        "__AVR_ATmega32u4__"
        "F_CPU=16000000L"
    )
fi

echo "🎯 Using platform: $PRIMARY_PLATFORM"
echo "📋 Board FQBN: $BOARD_FQBN"
echo "🏷️  Board: $BOARD_NAME"

# Find relevant paths for the selected platform
echo "🔍 Searching for Arduino paths..."
ARDUINO_CORE_PATHS=()
ARDUINO_VARIANT_PATHS=()
COMPILER_PATHS=()
INCLUDE_PATHS=()

case $PRIMARY_PLATFORM in
    "arduino:avr")
        ARDUINO_CORE_PATH=$(find ~/.arduino15 -path "*/arduino/hardware/avr/*/cores/arduino" -type d | head -1)
        # Select variant based on detected board
        if [[ "$BOARD_FQBN" == *"uno"* ]]; then
            ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/arduino/hardware/avr/*/variants/standard" -type d | head -1)
        elif [[ "$BOARD_FQBN" == *"leonardo"* ]]; then
            ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/arduino/hardware/avr/*/variants/leonardo" -type d | head -1)
        elif [[ "$BOARD_FQBN" == *"nano"* ]]; then
            ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/arduino/hardware/avr/*/variants/eightanaloginputs" -type d | head -1)
        else
            ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/arduino/hardware/avr/*/variants/standard" -type d | head -1)
        fi
        AVR_GCC_PATH=$(find ~/.arduino15 -path "*/tools/avr-gcc/*/avr/include" -type d | head -1)
        AVR_GCC_LIB_PATH=$(find ~/.arduino15 -path "*/tools/avr-gcc/*/lib/gcc/avr/*/include" -type d | grep -v plugin | head -1)
        COMPILER_PATH=$(find ~/.arduino15 -path "*/tools/avr-gcc/*/bin/avr-gcc" -type f | head -1)
        INCLUDE_PATHS=("$ARDUINO_CORE_PATH" "$ARDUINO_VARIANT_PATH" "$AVR_GCC_PATH" "$AVR_GCC_LIB_PATH")
        ;;
    "esp8266:esp8266")
        ARDUINO_CORE_PATH=$(find ~/.arduino15 -path "*/esp8266/hardware/esp8266/*/cores/esp8266" -type d | head -1)
        ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/esp8266/hardware/esp8266/*/variants/nodemcu" -type d | head -1)
        ESP8266_TOOLS_PATH=$(find ~/.arduino15 -path "*/esp8266/hardware/esp8266/*/tools/sdk/include" -type d | head -1)
        ESP8266_LIBC_PATH=$(find ~/.arduino15 -path "*/esp8266/hardware/esp8266/*/tools/sdk/libc/xtensa-lx106-elf/include" -type d | head -1)
        COMPILER_PATH=$(find ~/.arduino15 -path "*/esp8266/tools/xtensa-lx106-elf-gcc/*/bin/xtensa-lx106-elf-gcc" -type f | head -1)
        INCLUDE_PATHS=("$ARDUINO_CORE_PATH" "$ARDUINO_VARIANT_PATH" "$ESP8266_TOOLS_PATH" "$ESP8266_LIBC_PATH")
        ;;
    "esp32:esp32")
        ARDUINO_CORE_PATH=$(find ~/.arduino15 -path "*/esp32/hardware/esp32/*/cores/esp32" -type d | head -1)
        ARDUINO_VARIANT_PATH=$(find ~/.arduino15 -path "*/esp32/hardware/esp32/*/variants/nodemcu-32s" -type d | head -1)
        ESP32_TOOLS_PATH=$(find ~/.arduino15 -path "*/esp32/hardware/esp32/*/tools/sdk/esp32/include" -type d | head -1)
        COMPILER_PATH=$(find ~/.arduino15 -path "*/esp32/tools/xtensa-esp32-elf-gcc/*/bin/xtensa-esp32-elf-gcc" -type f | head -1)
        INCLUDE_PATHS=("$ARDUINO_CORE_PATH" "$ARDUINO_VARIANT_PATH")
        # Add ESP32 SDK includes
        if [ -n "$ESP32_TOOLS_PATH" ]; then
            ESP32_INCLUDES=$(find "$ESP32_TOOLS_PATH" -name include -type d)
            for inc in $ESP32_INCLUDES; do
                INCLUDE_PATHS+=("$inc")
            done
        fi
        ;;
esac

echo "📍 Found Arduino paths:"
for path in "${INCLUDE_PATHS[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
        echo "  ✅ $path"
    else
        echo "  ❌ $path (not found)"
    fi
done
echo "  🔨 Compiler: $COMPILER_PATH"

# Create VS Code C++ configuration
mkdir -p .vscode

# Build includePath array for JSON
INCLUDE_JSON=""
for path in "${INCLUDE_PATHS[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
        if [ -n "$INCLUDE_JSON" ]; then
            INCLUDE_JSON="$INCLUDE_JSON,"
        fi
        INCLUDE_JSON="$INCLUDE_JSON\"$path\""
    fi
done

# Build defines array for JSON
DEFINES_JSON=""
for define in "${DEFINES[@]}"; do
    if [ -n "$DEFINES_JSON" ]; then
        DEFINES_JSON="$DEFINES_JSON,"
    fi
    DEFINES_JSON="$DEFINES_JSON\"$define\""
done

cat > .vscode/c_cpp_properties.json << EOF
{
    "configurations": [
        {
            "name": "Arduino",
            "includePath": [
                "\${workspaceFolder}/**",
                $INCLUDE_JSON
            ],
            "defines": [
                $DEFINES_JSON
            ],
            "compilerPath": "$COMPILER_PATH",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "gcc-x64"
        }
    ],
    "version": 4
}
EOF

# Update workspace Arduino configuration
cat > .vscode/arduino.json << EOF
{
    "sketch": "src/hello-world/hello-world.ino",
    "board": "$BOARD_FQBN",
    "output": "output",
    "port": "$ARDUINO_PORT",
    "programmer": "arduino:usbtinyisp"
}
EOF

# Update workspace settings
cat > .vscode/settings.json << EOF
{
    "arduino.useArduinoCli": true,
    "arduino.logLevel": "verbose"
}
EOF

# Fix permissions for Arduino devices
echo "🔒 Setting up device permissions..."
sudo usermod -a -G dialout,sudo vscode || true
# Set permissions for common Arduino device paths
for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        sudo chmod 666 "$device" 2>/dev/null || true
        echo "   📱 Set permissions for $device"
    fi
done

echo "✅ Arduino development environment setup complete!"
echo "🎯 Platform: $PRIMARY_PLATFORM"
echo "🏷️  Board: $BOARD_NAME ($BOARD_FQBN)"
echo "📱 Port: $ARDUINO_PORT"
echo ""
echo "📋 You can now:"
echo "   - Use IntelliSense with Arduino functions"
echo "   - Compile with: arduino-cli compile --fqbn $BOARD_FQBN src/hello-world"
echo "   - Upload with: arduino-cli upload -p $ARDUINO_PORT --fqbn $BOARD_FQBN src/hello-world"