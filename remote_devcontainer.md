# Guide: Remote Arduino Development with VSCode SSH

## Overview

This guide outlines the steps to connect an Arduino board plugged into your **local machine** to this devcontainer, even when the devcontainer is running on a **remote SSH host**.

The core idea is to create a "serial-over-TCP" proxy that is securely tunneled through your VSCode SSH connection.

## Quick Start

For those who want to get started quickly:

1. **Local Machine:** Copy `local-arduino-proxy.sh` to your local machine and run it
2. **VSCode:** Forward port 5000 in the "Ports" tab
3. **Container:** Modify Dockerfile, setup script, and arduino.json (see detailed steps below)
4. **Rebuild:** Rebuild the devcontainer and test

📖 **First time?** Read the detailed step-by-step instructions below.

## System Components

1. **Local Machine (with Arduino)**: The computer where your Arduino is physically connected via USB. It will run a `socat` server.
2. **VSCode SSH Connection**: This will act as a secure tunnel, using its "Port Forwarding" feature to bridge the gap between your local machine and the remote container.
3. **Remote Devcontainer**: This is where your code and the Arduino CLI run. It will be modified to install `socat` as a client and create a *virtual* serial port that connects back to your local machine.

-----

## Step-by-Step Instructions

### Step 1: On Your Local Machine (with the Arduino)

You must first expose your Arduino's serial port as a network (TCP) port on your local machine.

#### Option A: Automated Setup (Recommended)

Use the included helper script for automatic board detection and setup:

1. **Copy the helper script** to your local machine:

    Copy `local-arduino-proxy.sh` from this repository to your local machine.

2. **Install prerequisites** on your local machine:

    ```bash
    # Linux (Debian/Ubuntu)
    sudo apt install socat
    
    # Linux (Fedora/RHEL)
    sudo dnf install socat
    
    # macOS
    brew install socat
    
    # Optional but recommended: Install arduino-cli for auto-detection
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
    ```

3. **Run the helper script**:

    ```bash
    # Automatic detection (requires arduino-cli)
    ./local-arduino-proxy.sh
    
    # Or manually specify the port
    ./local-arduino-proxy.sh /dev/ttyACM0
    
    # Or specify custom TCP port
    ./local-arduino-proxy.sh /dev/ttyACM0 5000
    ```

The script will:

- ✅ Auto-detect your connected Arduino board
- ✅ Show board information and port
- ✅ Start the serial-to-TCP proxy on port 5000
- ✅ Provide helpful error messages if something goes wrong

**Leave this terminal running.** Your Arduino is now available at `localhost:5000` on your local machine.

#### Option B: Manual Setup

If you prefer to set up manually without the helper script:

1. **Find your Arduino's port name:**

      - **Linux/macOS**: `/dev/ttyACM0` (or similar)
      - **Windows**: `COM3` (or similar)

    You can list available ports:

    ```bash
    # Linux/macOS
    ls /dev/tty* | grep -E 'ACM|USB'
    
    # Windows (PowerShell)
    Get-WmiObject Win32_SerialPort | Select-Object Name,DeviceID
    ```

2. **Install `socat`** (on Linux/macOS) or an equivalent for Windows.

3. **Run the following command** in a terminal on your local machine (using your port name):

    ```bash
    # Example for Linux/macOS:
    socat TCP-LISTEN:5000,fork,reuseaddr FILE:/dev/ttyACM0,b115200,raw,echo=0

    # Example for Windows (using WSL or a Windows port of socat):
    socat TCP-LISTEN:5000,fork,reuseaddr FILE:COM3,b115200,raw,echo=0
    ```

**Leave this terminal running.** Your Arduino is now available at `localhost:5000` on your local machine.

### Step 2: Configure VSCode Port Forwarding

1. Connect to your remote host using the **Remote - SSH** extension.
2. Open this project folder and **Reopen in Container**.
3. Once the devcontainer is running, go to the **"Ports" tab** in VSCode (in the bottom panel).
4. Click **"Forward a Port"** and forward port `5000`.

This tells VSCode to securely tunnel any traffic from `localhost:5000` *inside the container* to `localhost:5000` *on your local machine*.

### Step 3: Configure the Devcontainer

You need to modify three files in this project to complete the connection.

#### A. Install `socat` in the Container

Modify `.devcontainer/Dockerfile` to include `socat` in the `apt install` list.

```diff
ARG VARIANT
FROM mcr.microsoft.com/vscode/devcontainers/cpp:0-${VARIANT}

...

RUN apt update \
    && apt install -y \
    git \
    bash-completion \
    curl \
    ca-certificates \
    tar \
    gzip \
    jq \
+   socat

# Configure dialout group mapping without external envfile.
...
```

#### B. Create the Virtual Serial Port

Modify `.devcontainer/setup-arduino.sh` to add the `socat` client command. This creates a new virtual port inside the container that connects to the forwarded port.

**Important:** This command should run *before* the script tries to auto-detect boards, as auto-detection will fail.

```diff
#!/bin/bash
set -e

echo "🔧 Setting up Arduino development environment..."

+ echo "🔗 Creating remote serial port proxy..."
+ # Connects to the port forwarded by VSCode (localhost:5000)
+ # and creates a new virtual port at /dev/ttyREMOTE
+ # The '&' runs it in the background.
+ socat PTY,link=/dev/ttyREMOTE,raw,echo=0,waitslave TCP:localhost:5000 &
+ echo "   Virtual port /dev/ttyREMOTE created."

# Ensure Arduino CLI is available and update core index
arduino-cli core update-index

...

# Auto-detect connected Arduino boards
echo "🔍 Scanning for connected Arduino boards..."
BOARD_LIST=$(arduino-cli board list --format text)
echo "$BOARD_LIST"
```

#### C. Configure the Arduino Extension

The board auto-detection logic in `setup-arduino.sh` will no longer find a local board and will overwrite `.vscode/arduino.json` with a fallback.

You must manually edit `.vscode/arduino.json` to point to your new virtual port.

```diff
{
    "sketch": "src/hello-world/hello-world.ino",
    "board": "arduino:avr:uno",
    "output": "output",
-   "port": "/dev/ttyACM0",
+   "port": "/dev/ttyREMOTE",
    "programmer": "arduino:usbtinyisp"
}
```

**Note:** You may also need to modify `setup-arduino.sh` to *prevent* it from overwriting the `"port"` setting in `.vscode/arduino.json`. A simple way is to comment out the `DETECTED_PORT` logic and the part of the script that writes the `arduino.json` file, as you will now be managing it manually.

### Step 4: Rebuild and Run

1. Save all your file changes.
2. Use the VSCode Command Palette (`Ctrl+Shift+P`) to run **"Dev Containers: Rebuild Container"**.
3. Ensure your local `socat` server (from Step 1) is running.
4. Ensure your VSCode port forwarding (from Step 2) is active.

You should now be able to compile and **upload** to your Arduino from the remote devcontainer. The Arduino CLI will send the data to `/dev/ttyREMOTE`, which `socat` will forward through the VSCode SSH tunnel to your local machine, and finally to your physical USB port.

-----

## Troubleshooting

### Connection Issues

If uploads fail, verify each part of the chain:

1. **Local proxy is running:**

    ```bash
    # On your local machine, check if socat is running
    ps aux | grep socat
    # Should show: socat TCP-LISTEN:5000...
    ```

2. **VSCode port forwarding is active:**

    - Check the "Ports" tab in VSCode
    - Port 5000 should show as "Forwarded"

3. **Virtual serial port exists in container:**

    ```bash
    # In the devcontainer terminal
    ls -l /dev/ttyREMOTE
    # Should show a link to a pty device
    ```

4. **Test the connection:**

    ```bash
    # In the devcontainer terminal
    echo "test" > /dev/ttyREMOTE
    # If this hangs or errors, the connection chain is broken
    ```

### Common Problems

- **"No such file or directory" for /dev/ttyREMOTE:**
  - The `socat` background process in `setup-arduino.sh` may have failed
  - Check if port 5000 is being forwarded in VSCode
  - Verify your local proxy is running

- **Upload hangs or times out:**
  - Check that the Arduino is physically connected to your local machine
  - Verify the baud rate matches (default: 115200)
  - Try restarting the local proxy script

- **Permission denied errors:**
  - On your local machine, ensure you have permission to access the serial port
  - Linux: Add your user to the `dialout` group: `sudo usermod -aG dialout $USER`

### Helper Script Issues

If `local-arduino-proxy.sh` can't detect your board:

```bash
# Manually check what arduino-cli sees
arduino-cli board list

# List all serial devices
ls -l /dev/tty* | grep -E 'ACM|USB|usbmodem|usbserial'

# Run the script with explicit port
./local-arduino-proxy.sh /dev/ttyACM0
```

-----

## Summary

This setup creates a secure tunnel for Arduino development across three layers:

``` text
┌──────────────────────────────────────────────────────────────┐
│ LOCAL MACHINE (Your Computer)                                │
│                                                              │
│  Arduino USB ──► socat server ──► localhost:5000             │
│                   (local-arduino-proxy.sh)                   │
└────────────────────────────┬─────────────────────────────────┘
                             │
                     VSCode SSH Tunnel
                     (Port Forwarding)
                             │
┌────────────────────────────▼─────────────────────────────────┐
│ REMOTE DEVCONTAINER (SSH Host)                               │
│                                                              │
│  localhost:5000 ──► socat client ──► /dev/ttyREMOTE          │
│                                            │                 │
│                                            ▼                 │
│                                    Arduino CLI Upload        │
└──────────────────────────────────────────────────────────────┘
```

### Key Benefits

- ✅ **Develop remotely** with powerful SSH host resources
- ✅ **Test locally** with physical Arduino hardware
- ✅ **Secure connection** through VSCode's encrypted SSH tunnel
- ✅ **No hardware passthrough** complexities (no USB/IP required)
- ✅ **Simple setup** with automated helper script

### Files Modified

To enable this setup, you'll modify:

- `.devcontainer/Dockerfile` - Add socat package
- `.devcontainer/setup-arduino.sh` - Create virtual serial port
- `.vscode/arduino.json` - Point to /dev/ttyREMOTE
- `local-arduino-proxy.sh` - Run on local machine (new file)
