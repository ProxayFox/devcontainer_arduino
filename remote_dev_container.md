# Remote Arduino Development Guide

This guide covers detailed setup and troubleshooting for remote Arduino development using VS Code dev containers.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Arduino Board Compatibility](#arduino-board-compatibility)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Known Limitations](#known-limitations)

## Overview

Remote Arduino development allows you to:

- 🖥️ Develop in a dev container on a remote server
- 🔌 Keep your Arduino physically connected to your local machine
- 🌐 Bridge the serial connection over TCP/IP
- 📝 Get full IntelliSense and debugging capabilities

## Architecture

```text
┌─────────────────┐    TCP/IP     ┌──────────────────┐
│   Local Machine │◄─────────────►│   Remote Server  │
│                 │               │                  │
│ ┌─────────────┐ │               │ ┌──────────────┐ │
│ │   Arduino   │ │               │ │ Dev Container│ │
│ │             │ │               │ │              │ │
│ └──────┬──────┘ │               │ │  VS Code     │ │
│        │ USB    │               │ │  Arduino CLI │ │
│ ┌──────▼──────┐ │               │ │  Extensions  │ │
│ │local-arduino│ │               │ └──────────────┘ │
│ │  -proxy.sh  │ │               │                  │
│ │(socat proxy)│ │               │                  │
│ └─────────────┘ │               │                  │
└─────────────────┘               └──────────────────┘
```

## Arduino Board Compatibility

### ✅ Excellent Remote Support

| Board | Chip | Bootloader | Notes |
|-------|------|------------|-------|
| **Arduino Leonardo** | ATmega32u4 | USB-native | **RECOMMENDED** - No DTR reset required |
| **Arduino Micro** | ATmega32u4 | USB-native | Same as Leonardo, excellent for remote |
| **ESP32 DevKit** | ESP32 | ROM bootloader | Works well, auto-reset via EN pin |
| **ESP8266 NodeMCU** | ESP8266 | ROM bootloader | Good remote compatibility |

### ⚠️ Limited Remote Support

| Board | Chip | Issue | Workaround |
|-------|------|-------|------------|
| **Arduino Uno** | ATmega328P | Requires DTR/RTS reset | Manual reset button timing |
| **Arduino Nano** | ATmega328P | Same as Uno | Manual reset or use CH340G variant |
| **Arduino Pro Mini** | ATmega328P | External programmer needed | Use USB-to-serial adapter |

### ❌ Not Recommended for Remote

| Board | Chip | Issue | Alternative |
|-------|------|-------|-------------|
| **Arduino Uno R4** | Various | Complex USB handling | Use Leonardo or ESP32 |
| **Custom ATmega328P** | ATmega328P | No auto-reset circuit | Add external reset control |

## Prerequisites

### Local Machine (where Arduino is connected)

#### Linux/macOS

```bash
# Debian/Ubuntu
sudo apt install socat

# Fedora/RHEL
sudo dnf install socat

# macOS
brew install socat

# NixOS
nix-shell -p socat
# or with flakes: nix develop
```

#### Windows

```powershell
# Using winget
winget install -e --id Firejox.WinSocat
```

More info: [WinSocat GitHub](https://github.com/firejox/WinSocat)

#### Optional: Arduino CLI for Auto-Detection

```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# Windows
winget install ArduinoSA.CLI
```

### Remote Server

- Docker and VS Code with Remote-Containers extension
- Network connectivity to local machine
- Port 5000 available (or custom port)

## Step-by-Step Setup

### 1. Prepare Local Machine

1. **Connect your Arduino** to your local machine via USB

2. **Identify the Arduino port**:

   ```bash
   # Linux
   ls /dev/tty* | grep -E "(ACM|USB)"
   
   # macOS  
   ls /dev/cu.*
   
   # Windows
   # Use Device Manager to find COM port
   ```

3. **Test Arduino connection** (optional):

   ```bash
   arduino-cli board list
   ```

### 2. Start the Local Proxy

#### Automatic Detection (Recommended)

```bash
./local-arduino-proxy.sh
```

#### Manual Port Specification

```bash
# Linux/macOS
./local-arduino-proxy.sh /dev/ttyACM0

# Windows
./local-arduino-proxy.sh COM3
```

#### Custom TCP Port

```bash
./local-arduino-proxy.sh /dev/ttyACM0 8080
```

**Expected Output:**

```text
🔍 Auto-detecting Arduino board...
📱 Found Arduino board:
   Port: /dev/ttyACM0
   Board: Arduino Leonardo
   FQBN: arduino:avr:leonardo

🌐 Starting TCP proxy...
✅ Arduino proxy started successfully!
   Local port: /dev/ttyACM0
   TCP port: localhost:5000
   
🔧 Keep this terminal open while developing
🌐 Your Arduino is now accessible at localhost:5000
```

### 3. Setup Remote Dev Container

1. **Open the project** in VS Code on your remote server

2. **Reopen in container**: `Ctrl+Shift+P` → "Remote-Containers: Reopen in Container"

3. **Configure for remote mode**:

   ```bash
   .devcontainer/setup-arduino.sh --remote --host YOUR_LOCAL_IP --port 5000
   ```

   Replace `YOUR_LOCAL_IP` with your local machine's IP address.

### 4. Create the Arduino Bridge

1. **Run the bridge script**:

   ```bash
   ./start-arduino-bridge.sh
   ```

2. **Expected output**:

   ```text
   🌐 Setting up Arduino TCP-to-serial bridge...
   ✅ Port forwarding is working
   🔗 Creating serial bridge...
   ✅ Serial bridge created at /tmp/arduino_bridge
      PID: 1234
      Bridge: /tmp/arduino_bridge ↔ 192.168.1.13:5000

   🎯 Arduino is now ready for uploads!
   ```

### 5. Test the Setup

1. **Compile a sketch**:

   ```bash
   arduino-cli compile --fqbn arduino:avr:leonardo src/hello-world
   ```

2. **Upload to Arduino**:

   ```bash
   arduino-cli upload -p /tmp/arduino_bridge --fqbn arduino:avr:leonardo src/hello-world
   ```

3. **Use VS Code Arduino extension** normally - it should detect `/tmp/arduino_bridge` as the Arduino port

## Troubleshooting

### Connection Issues

#### "Cannot connect to X.X.X.X:5000"

- ✅ Verify `local-arduino-proxy.sh` is running on local machine
- ✅ Check firewall settings on local machine
- ✅ Confirm IP address is correct
- ✅ Test with `telnet LOCAL_IP 5000` from remote machine

#### "Port forwarding not working"

- ✅ VS Code port forwarding may conflict with direct IP access
- ✅ Use direct IP address instead of localhost
- ✅ Check VS Code "Ports" panel for forwarded ports

### Upload Issues

#### Arduino Uno: "ioctl('TIOCMGET'): Inappropriate ioctl for device"

**Cause**: Arduino Uno requires DTR/RTS reset signals that cannot pass through TCP

**Solutions**:

1. **Switch to Leonardo** (recommended):

   ```bash
   # Update arduino.json
   {
     "board": "arduino:avr:leonardo"
   }
   ```

2. **Manual reset timing** (unreliable):
   - Start upload command
   - Press reset button when avrdude begins connecting
   - Timing is critical and often fails

3. **Hardware modification** (advanced):
   - Add ESP8266/ESP32 to control reset signal via network
   - Requires custom circuit design

#### ESP32/ESP8266: Upload Failures

- ✅ Try pressing BOOT button during upload
- ✅ Check baud rate in arduino.json
- ✅ Verify correct board variant selected

### Performance Issues

#### Slow Upload Speeds

- ✅ Network latency affects upload speed
- ✅ Use wired connection instead of WiFi
- ✅ Reduce upload baud rate for stability

#### Connection Timeouts

- ✅ Increase timeout values in arduino-cli config
- ✅ Check for network packet loss
- ✅ Use TCP keep-alive settings

### Bridge Management

#### "Bridge already exists"

```bash
# Kill existing bridge
pkill -f "socat.*pty.*TCP"

# Restart bridge
./start-arduino-bridge.sh
```

#### "Permission denied" on /tmp/arduino_bridge

```bash
# Fix permissions
sudo chmod 666 /tmp/arduino_bridge

# Or restart bridge with proper permissions
```

## Advanced Configuration

### Custom Bridge Configuration

Create a custom bridge script with specific options:

```bash
#!/bin/bash
# custom-bridge.sh

# Enhanced bridge with logging and error handling
socat -d -d -v \
  pty,link=/tmp/arduino_bridge,raw,echo=0,user=vscode,group=dialout,mode=666 \
  TCP:192.168.1.13:5000,keepalive,keepidle=10,keepintvl=5,keepcnt=3 \
  2>&1 | tee /tmp/bridge.log &

echo "Bridge PID: $!" > /tmp/bridge.pid
```

### Network Security

For production deployments, consider:

1. **SSH Tunneling**:

   ```bash
   # On remote server
   ssh -L 5000:localhost:5000 user@local-machine
   ```

2. **VPN Connection**:
   - Use OpenVPN or WireGuard
   - More secure than direct TCP

3. **Authentication**:
   - Add authentication layer to proxy script
   - Use TLS/SSL encryption for data transmission

### Multiple Arduino Support

Handle multiple Arduinos on different ports:

```bash
# local-multi-proxy.sh
./local-arduino-proxy.sh /dev/ttyACM0 5000 &  # Arduino 1
./local-arduino-proxy.sh /dev/ttyACM1 5001 &  # Arduino 2
./local-arduino-proxy.sh /dev/ttyACM2 5002 &  # Arduino 3
```

## Known Limitations

### Hardware Control Signals

- ❌ **DTR/RTS signals cannot pass through TCP** (affects Uno/Nano)
- ❌ **Hardware flow control not supported**
- ❌ **Break signals not transmitted**

### Bootloader Compatibility

- ❌ **STK500v1 protocol issues** with TCP bridges
- ❌ **Auto-reset timing problems** over network
- ❌ **Baud rate changes during upload** may cause sync issues

### Network Dependencies

- ❌ **Network latency affects upload reliability**
- ❌ **Connection drops cause upload failures**
- ❌ **Firewall/NAT configuration required**

### Performance Considerations

- ⚠️ **Upload speed limited by network bandwidth**
- ⚠️ **Serial monitor may have increased latency**
- ⚠️ **Large sketches take longer to upload**

## Best Practices

### For Reliable Remote Development

1. **Choose the right Arduino**:
   - Use **Leonardo/Micro** for best compatibility
   - Avoid **Uno/Nano** unless necessary

2. **Network optimization**:
   - Use wired connections when possible
   - Minimize network hops between machines
   - Configure proper MTU sizes

3. **Development workflow**:
   - Test locally first before remote upload
   - Use version control for code synchronization
   - Keep local backups of working configurations

4. **Monitoring and logging**:
   - Monitor bridge connection status
   - Log upload attempts for debugging
   - Set up automated bridge restart on failure

### Recommended Hardware Setup

For the most reliable remote Arduino development experience:

```text
Local Machine: Arduino Leonardo + USB cable
             ↓
Network: Gigabit Ethernet (preferred) or 5GHz WiFi
             ↓
Remote Server: Docker container with this devcontainer
```

This configuration provides the best balance of compatibility, performance, and reliability for remote Arduino development.
