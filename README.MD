# VSCODE Devcontainer for Arduino

This is a self-contained environment that allows compiling and uploading
Arduino source code without having to install anything on your computer, beside VSCode and Docker. It uses the VSCode's devcontainer built-in feature.

## Licensing

The included Docker file, the devcontainer.json file and the hello-world sample are licensed under the MIT License. All other files are governed by their respective licenses.

## How it works

This devcontainer is based on Microsoft's CPP devcontainer using Debian and contains the required extensions to facilitate Arduino development.  
The devcontainer is configured to launch the container with `--privileged` options. This is required to access the serial ports from inside the Docker container. If your feel unsafe about that, you can remove this option and add an UDEV rule to configure the file permissions on the Arduino device automatically.

## Environment

This devcontainer has been tested with the following environment:

- Fedora 36
- Docker 20.10.17
- VSCode 1.69.2

## How to use the devcontainer

1) **Choose your Arduino platform** by editing `devcontainer.json`:
   - **Default (Arduino AVR)**: Leave `PACKAGE_URL` and `PLATFORM` empty
   - **ESP8266**: Set `PACKAGE_URL` to ESP8266 board manager URL and `PLATFORM` to `"esp8266:esp8266"`
   - **ESP32**: Set `PACKAGE_URL` to ESP32 board manager URL and `PLATFORM` to `"esp32:esp32"`
   - **See `.devcontainer/PLATFORM_EXAMPLES.md` for complete examples**

2) Open the project in VSCode: `File->Open Folder`

3) Reopen it in devcontainer:
   1) `CTRL+SHIFT+P` to open the command pallet
   2) `Remote-Containers: Reopen in container`

4) **Wait for automatic setup**: The devcontainer will automatically:
   - Install Arduino CLI and specified cores
   - Auto-detect your platform and configure IntelliSense accordingly
   - Set up proper include paths and compiler settings
   - Configure VS Code Arduino extension

## Platform Auto-Detection

The setup script automatically detects installed Arduino cores and configures the environment for the best available platform:

- **🏆 Priority Order**: ESP32 > ESP8266 > Arduino AVR
- **🎯 Smart Configuration**: Include paths, compiler settings, and board definitions automatically set
- **📋 Board Selection**: Automatically selects optimal board (e.g., NodeMCU for ESP8266, ESP32 Dev Module for ESP32)

## Inside the devcontainer

The Arduino development environment is fully configured and ready to use. You'll have:

- ✅ **Full IntelliSense support** for Arduino functions (`Serial`, `digitalWrite`, etc.)
- ✅ **Arduino CLI** pre-installed with AVR core
- ✅ **VS Code Arduino extension** properly configured
- ✅ **Automatic compilation** and upload capabilities

### Quick Commands

**From Terminal:**

```bash
# Compile the sketch
arduino-cli compile --fqbn arduino:avr:leonardo src/hello-world

# Upload to device (make sure device is connected)
arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:leonardo src/hello-world
```

**From VS Code (using Command Palette or shortcuts):**

Most of the option below are also available from the status bar

### Selecting the Board

From the command pallet, type `Arduino: Board config`

### Opening the serial monitor

From the command pallet, type `Arduino: Open serial monitor`

### Opening the library manager

From the command pallet, type `Arduino: Library manager`

### Working with the code

`ALT-CTRL-R`: Compile only  
`ALT-CTRL-U`: Compile and upload to the Arduino device

For more information about the Arduino extension for VSCode, consult [this page](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.vscode-arduino).

## External librairies

If you need to install external librairies, use the `arduino-cli lib install` command. See the end of the Docker files for more information.

## Remote Development Setup

### Using Arduino with Remote Dev Containers

If you want to develop in a remote dev container while your Arduino is physically connected to your local machine, you can use the included `local-arduino-proxy.sh` script to forward the serial connection over TCP.

#### Prerequisites

**Local Machine (where Arduino is connected):**

- **Linux/macOS**: Install `socat`

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

- **Windows**: Install `winsocat`

  ```powershell
  # Using winget
  winget install -e --id Firejox.WinSocat
  ```

  More info: [WinSocat GitHub](https://github.com/firejox/WinSocat)

- **Optional**: `arduino-cli` for auto-detection of Arduino boards

#### How to Use

1. **On your local machine** (where Arduino is connected), run the proxy script:

   ```bash
   ./local-arduino-proxy.sh
   ```

   The script will:
   - ✅ Auto-detect your Arduino board (if `arduino-cli` is installed)
   - ✅ Start a TCP proxy on `localhost:5000`
   - ✅ Forward all traffic to/from your Arduino

   **Manual port specification** (if auto-detection fails):

   ```bash
   # Linux/macOS
   ./local-arduino-proxy.sh /dev/ttyACM0
   
   # Windows
   ./local-arduino-proxy.sh COM3
   ```

   **Custom TCP port**:

   ```bash
   ./local-arduino-proxy.sh /dev/ttyACM0 8080
   ```

2. **Keep the terminal window open** - The proxy needs to run while you're developing

3. **Connect from remote dev container**: Your Arduino is now accessible at `localhost:5000` from your remote machine

#### Cross-Platform Support

The `local-arduino-proxy.sh` script supports:

- ✅ **Linux** - Uses standard `socat`
- ✅ **macOS** - Uses standard `socat`
- ✅ **Windows** - Uses `winsocat` (WinSocat project)
- ✅ **WSL** - Uses `socat` in WSL environment
- ✅ **NixOS** - Includes in flake dependencies

The script automatically detects which tool is available and uses the appropriate one.

#### Troubleshooting

##### "socat/winsocat is not installed"

- Follow the installation instructions above for your platform

##### "No Arduino board detected"

- Install `arduino-cli` for auto-detection, OR
- Manually specify the port: `./local-arduino-proxy.sh /dev/ttyACM0`

##### "Port already in use"

- Another application is using port 5000
- Specify a different port: `./local-arduino-proxy.sh /dev/ttyACM0 8080`
