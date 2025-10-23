# Arduino DevContainer Setup

This directory contains the configuration for the Arduino development container.

## Files

- **`devcontainer.json`**: Main devcontainer configuration
- **`Dockerfile`**: Container build instructions with Arduino CLI installation
- **`setup-arduino.sh`**: Post-creation script that automatically configures the Arduino environment
- **`PLATFORM_EXAMPLES.md`**: Example configurations for different Arduino platforms

## What Gets Automatically Configured

When the devcontainer is created, the following setup happens automatically:

### 1. Arduino CLI & Cores

- Arduino CLI is installed during container build
- Arduino AVR core is always installed for basic Arduino support
- Additional cores (ESP8266, ESP32, etc.) can be configured via build arguments
- Core index is updated for latest package information

### 2. VS Code Configuration

- **C++ IntelliSense**: Automatically configured with detected platform include paths and compiler definitions
- **Arduino Extension**: Installed and configured to use Arduino CLI
- **Project Settings**: Board FQBN, port, and sketch location auto-configured based on detected platform

### 3. Board Auto-Detection & Platform Configuration

- **Smart Board Detection**: Automatically detects connected Arduino boards using `arduino-cli board list`
- **Dynamic Configuration**: Workspace automatically configured based on detected board:
  - Port (e.g., `/dev/ttyACM0`, `/dev/ttyUSB0`)
  - Board FQBN (e.g., `arduino:avr:uno`, `esp32:esp32:nodemcu-32s`)
  - Board-specific compiler defines and variants
- **Supported Boards**: Arduino Uno, Leonardo, Nano, ESP8266, ESP32, and more
- **Smart Platform Selection**: Falls back to installed cores if no board detected
- **Priority Order**: Connected Board > ESP32 > ESP8266 > Arduino AVR
- **Dynamic Paths**: Include paths and compiler settings automatically detected for the selected platform
- **Permission Handling**: Automatically fixes device permissions for upload access

## Board Detection Process

The setup script automatically detects and configures your Arduino development environment:

### 1. Automatic Board Detection

```bash
arduino-cli board list
```

**Example Output:**

```bash
Port         Protocol Type              Board Name  FQBN            Core
/dev/ttyACM0 serial   Serial Port (USB) Arduino Uno arduino:avr:uno arduino:avr
```

### 2. Smart Configuration

Based on detected board, the script automatically configures:

- **VS Code Arduino Extension** (`arduino.json`)
- **C++ IntelliSense** (`c_cpp_properties.json`)
- **Board-specific settings** (FQBN, port, variant, defines)
- **Device permissions** for upload access

### 3. Supported Board Types

| Board Family | Example FQBN | Variant | Defines | Tested |
|--------------|--------------|---------|---------|--------|
| Arduino Uno | `arduino:avr:uno` | `standard` | `ARDUINO_AVR_UNO`, `__AVR_ATmega328P__` | ✅ |
| Arduino Leonardo | `arduino:avr:leonardo` | `leonardo` | `ARDUINO_AVR_LEONARDO`, `__AVR_ATmega32u4__` | ❌ |
| Arduino Mega 2560 | `arduino:avr:mega` | `standard` | `ARDUINO_AVR_MEGA2560`, `__AVR_ATmega2560__` | ✅ |
| Arduino Nano | `arduino:avr:nano` | `eightanaloginputs` | `ARDUINO_AVR_NANO`, `__AVR_ATmega328P__` | ✅ |
| ESP8266 | `esp8266:esp8266:*` | `nodemcu` | `ARDUINO_ESP8266_*`, `ESP8266` | ❌ |
| ESP32 | `esp32:esp32:*` | `nodemcu-32s` | `ARDUINO_NodeMCU_32S`, `ESP32` | ❌ |

### 4. Fallback Behavior

If no board is detected, the script falls back to using installed cores with this priority:

1. ESP32 (if `esp32:esp32` core installed)
2. ESP8266 (if `esp8266:esp8266` core installed)  
3. Arduino AVR (default fallback)

## Manual Setup vs DevContainer

| Manual Setup | DevContainer Setup |
|--------------|-------------------|
| Install Arduino IDE | ✅ Automatic |
| Install Arduino CLI | ✅ Automatic |
| Configure VS Code paths | ✅ Automatic |
| Install AVR core | ✅ Automatic |
| Setup IntelliSense | ✅ Automatic |
| Configure board settings | ✅ Automatic |
| Detect connected boards | ✅ Automatic |
| Set device permissions | ✅ Automatic |
| Configure board-specific variants | ✅ Automatic |
| Setup compiler defines | ✅ Automatic |

## Customization

### Configure Arduino Platform

Edit the `args` section in `devcontainer.json` to specify your target platform:

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11",
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    // Platform configuration
    "PACKAGE_URL": "http://arduino.esp8266.com/stable/package_esp8266com_index.json",
    "PLATFORM": "esp8266:esp8266"
}
```

**See `PLATFORM_EXAMPLES.md` for complete examples** including ESP8266, ESP32, SAMD, and more.

### Change Target Board

The setup script automatically selects the best board, but you can override it by editing `.vscode/arduino.json`:

```json
{
    "board": "esp8266:esp8266:d1_mini",  // Change to your specific board
    // ... rest of config
}
```

### Add More Cores

Multiple platforms can be specified comma-separated:

```json
"PACKAGE_URL": "http://arduino.esp8266.com/stable/package_esp8266com_index.json,https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json",
"PLATFORM": "esp8266:esp8266,esp32:esp32"
```

### Add Libraries

Add library installation to `setup-arduino.sh`:

```bash
# Install libraries
arduino-cli lib install "WiFi"
arduino-cli lib install "ArduinoJson"
```

## Troubleshooting

### Board Not Detected

If your board isn't automatically detected:

1. **Check Connection**: Ensure the Arduino is connected via USB
2. **Check Device**: Verify device appears in `/dev/`

   ```bash
   ls /dev/tty*
   ```

3. **Manual Detection**: Run board detection manually

   ```bash
   arduino-cli board list
   ```

4. **Permission Issues**: If you see permission denied errors:

   ```bash
   sudo chmod 666 /dev/ttyACM0  # Replace with your device
   ```

### Upload Permission Errors

The setup script automatically fixes permissions, but if you encounter issues:

```bash
# Check device permissions
ls -la /dev/ttyACM0

# Fix permissions (temporary)
sudo chmod 666 /dev/ttyACM0

# Add user to groups (permanent, requires restart)
sudo usermod -a -G dialout,sudo vscode
```

### Wrong Board Configuration

If the wrong board is detected, manually edit `.vscode/arduino.json`:

```json
{
    "sketch": "src/hello-world/hello-world.ino",
    "board": "arduino:avr:uno",  // Change to correct FQBN
    "output": "output",
    "port": "/dev/ttyACM0",      // Change to correct port
    "programmer": "arduino:usbtinyisp"
}
```

### Re-run Configuration

To re-detect and reconfigure:

```bash
bash .devcontainer/setup-arduino.sh
```

## Verification

Run the verification script to check that everything is working:

```bash
./verify-setup.sh
```

This will test Arduino CLI, core installation, VS Code configuration, and compilation.

### Manual Verification Commands

```bash
# Check Arduino CLI installation
arduino-cli version

# List installed cores
arduino-cli core list

# Check connected boards
arduino-cli board list

# Test compilation
arduino-cli compile --fqbn arduino:avr:uno src/hello-world

# Check VS Code configuration
cat .vscode/arduino.json
cat .vscode/c_cpp_properties.json
```
