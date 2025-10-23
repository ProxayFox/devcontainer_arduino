#!/bin/bash
# Arduino TCP-to-Serial Bridge Setup Script
# Run this script AFTER the dev container is fully started and port forwarding is active

echo "🌐 Setting up Arduino TCP-to-serial bridge..."

# Kill any existing socat processes for this port
pkill -f "socat.*pty.*TCP" 2>/dev/null || true

# Wait a moment for processes to clean up
sleep 1

# Test if the forwarded port is available
if ! timeout 5 bash -c "</dev/tcp/192.168.1.13/5000"; then
    echo "❌ Cannot connect to 192.168.1.13:5000"
    echo "   Make sure:"
    echo "   1. local-arduino-proxy.sh is running on your local machine"
    echo "   2. VS Code port forwarding is active (check Ports panel)"
    echo "   3. Port 5000 is forwarded from local to container"
    exit 1
fi

echo "✅ Port forwarding is working"

# Create a pseudo-terminal that bridges to the TCP connection
echo "🔗 Creating serial bridge..."
socat pty,link=/tmp/arduino_bridge,raw,echo=0 TCP:192.168.1.13:5000 &
SOCAT_PID=$!

# Wait for the link to be created
sleep 3

# Make sure the link was created successfully
if [ -L /tmp/arduino_bridge ]; then
    echo "✅ Serial bridge created at /tmp/arduino_bridge"
    echo "   PID: $SOCAT_PID"
    echo "   Bridge: /tmp/arduino_bridge ↔ 192.168.1.13:5000"
    echo ""
    echo "🎯 Arduino is now ready for uploads!"
    echo "   Use 'arduino-cli upload -p /tmp/arduino_bridge --fqbn YOUR_BOARD src/hello-world'"
    echo "   Or use the VS Code Arduino extension normally"
    
    # Save PID for later cleanup
    echo $SOCAT_PID > /tmp/arduino_bridge.pid
    
    # Keep the bridge running in the background
    disown
else
    echo "❌ Failed to create serial bridge"
    kill $SOCAT_PID 2>/dev/null
    exit 1
fi
