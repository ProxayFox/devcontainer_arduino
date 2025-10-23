#!/usr/bin/env bash
# Local Arduino Serial-to-TCP Proxy Script
# Run this script on your LOCAL machine (where Arduino is physically connected)
# 
# Prerequisites:
#   - socat installed (Linux/macOS: apt/brew install socat)
#   - arduino-cli installed (optional, for auto-detection)
#
# Usage:
#   ./local-arduino-proxy.sh [PORT] [TCP_PORT]
#
#   PORT:     (Optional) Arduino serial port. If not provided, auto-detects.
#   TCP_PORT: (Optional) TCP port to listen on. Default: 5000

set -e

TCP_PORT="${2:-5000}"
BAUD_RATE="115200"

echo "🔌 Arduino Serial-to-TCP Proxy"
echo "================================"

# Check if socat or winsocat is installed
SOCAT_CMD=""
if command -v socat &> /dev/null; then
    SOCAT_CMD="socat"
elif command -v winsocat &> /dev/null; then
    SOCAT_CMD="winsocat"
else
    echo """
      ❌ Error: socat/winsocat is not installed

      Install it with:
        - Linux (Debian/Ubuntu): sudo apt install socat
        - Linux (Fedora/RHEL):   sudo dnf install socat
        - NixOS:                 nix-shell -p socat
        - NixOS (Flakes):        nix develop # this will use the flake.nix
        - macOS:                 brew install socat
        - Windows (WSL):         sudo apt install socat
        - Windows (winget):      winget install -e --id Firejox.WinSocat # see https://github.com/firejox/WinSocat
    """
    exit 1
fi

echo "✓ Using: $SOCAT_CMD"

# Determine Arduino port
if [ -n "$1" ]; then
    # User provided port manually
    ARDUINO_PORT="$1"
    echo "📱 Using manually specified port: $ARDUINO_PORT"
else
    # Try to auto-detect using arduino-cli
    if command -v arduino-cli &> /dev/null; then
        echo "🔍 Auto-detecting Arduino board..."
        
        # Get board list and extract port
        BOARD_INFO=$(arduino-cli board list --format text 2>/dev/null | grep -E '^/dev/|^COM')
        
        if [ -z "$BOARD_INFO" ]; then
            echo """
              ❌ No Arduino board detected

              Please connect your Arduino and try again, or manually specify the port:
              ./local-arduino-proxy.sh /dev/ttyACM0
              ./local-arduino-proxy.sh COM3
            """
            exit 1
        fi
        
        ARDUINO_PORT=$(echo "$BOARD_INFO" | head -n1 | awk '{print $1}')
        BOARD_NAME=$(echo "$BOARD_INFO" | head -n1 | awk '{for(i=4;i<=NF-2;i++) printf "%s ", $i}')
        
        echo "📱 Found: ${BOARD_NAME}on $ARDUINO_PORT"
    else
        # No arduino-cli, try common ports
        echo "⚠️  arduino-cli not found, checking common ports..."
        
        # Check common Linux/macOS ports
        for port in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1 /dev/cu.usbmodem* /dev/cu.usbserial*; do
            if [ -e "$port" ]; then
                ARDUINO_PORT="$port"
                echo "📱 Found potential Arduino at: $ARDUINO_PORT"
                break
            fi
        done
        
        if [ -z "$ARDUINO_PORT" ]; then
            echo """
              ❌ Could not detect Arduino port

              Please install arduino-cli for auto-detection:
                curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

              Or manually specify the port:
                ./local-arduino-proxy.sh /dev/ttyACM0
                ./local-arduino-proxy.sh COM3
            """
            exit 1
        fi
    fi
fi


# Verify port exists
if [ ! -e "$ARDUINO_PORT" ] && [[ ! "$ARDUINO_PORT" =~ ^COM[0-9]+$ ]]; then
    echo """
      ❌ Error: Port $ARDUINO_PORT does not exist

      Available ports:
    """
    ls /dev/tty* 2>/dev/null | grep -E 'ACM|USB|usbmodem|usbserial' || echo "  (none found)"
    exit 1
fi

echo """
🔗 Starting proxy...
   Arduino Port: $ARDUINO_PORT
   TCP Port:     localhost:$TCP_PORT
   Baud Rate:    $BAUD_RATE

✅ Proxy is running. Press Ctrl+C to stop.
   Your Arduino is now accessible at localhost:$TCP_PORT
   Keep this terminal open while using the proxy.
"""

# Start socat/winsocat proxy
# This command:
#   - Listens on TCP port (default 5000)
#   - Forks for each connection
#   - Allows port reuse
#   - Connects to Arduino serial port with specified baud rate
#   - Enables raw mode and disables echo for binary data
echo "🚀 Starting proxy (press Ctrl+C to stop)..."
echo ""

# For Arduino Uno, we need to handle DTR reset properly
# Use rawer mode to better handle reset signals
$SOCAT_CMD TCP-LISTEN:${TCP_PORT},fork,reuseaddr FILE:${ARDUINO_PORT},b${BAUD_RATE},raw,echo=0
