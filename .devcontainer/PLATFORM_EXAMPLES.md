# Arduino DevContainer Platform Examples

This file contains example configurations for different Arduino-compatible platforms that you can use in your `devcontainer.json`.

## Standard Arduino AVR (Default)

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11", 
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "",
    "PLATFORM": ""
}
```

## ESP8266 Development

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11",
    "USER_NAME": "vscode", 
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "http://arduino.esp8266.com/stable/package_esp8266com_index.json",
    "PLATFORM": "esp8266:esp8266"
}
```

## ESP32 Development

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11",
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest", 
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json",
    "PLATFORM": "esp32:esp32"
}
```

## Arduino SAMD (Zero, MKR, Nano 33 IoT)

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11",
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20", 
    "PACKAGE_URL": "",
    "PLATFORM": "arduino:samd"
}
```

## Adafruit SAMD Boards

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11",
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "https://adafruit.github.io/arduino-board-index/package_adafruit_index.json",
    "PLATFORM": "adafruit:samd"
}
```

## Raspberry Pi Pico (RP2040)

```json
"args": {
    "VERSION": "1", 
    "VARIANT": "debian-11",
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json",
    "PLATFORM": "rp2040:rp2040"
}
```

## Multiple Platforms

You can install multiple platforms by combining them. The setup script will automatically detect and configure the best one:

```json
"args": {
    "VERSION": "1",
    "VARIANT": "debian-11", 
    "USER_NAME": "vscode",
    "ARDUINO_CLI_VERSION": "latest",
    "DIALOUT_GID": "20",
    "PACKAGE_URL": "http://arduino.esp8266.com/stable/package_esp8266com_index.json,https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json",
    "PLATFORM": "esp8266:esp8266,esp32:esp32"
}
```

## Platform Priority

The setup script will automatically choose platforms in this priority order:
1. ESP32 (if installed)
2. ESP8266 (if installed) 
3. Arduino AVR (default fallback)

## Board Configuration

After the container is created, you can change the specific board by editing `.vscode/arduino.json`:

### ESP8266 Boards
- `esp8266:esp8266:nodemcuv2` - NodeMCU 1.0
- `esp8266:esp8266:d1_mini` - Wemos D1 Mini
- `esp8266:esp8266:generic` - Generic ESP8266

### ESP32 Boards  
- `esp32:esp32:esp32dev` - ESP32 Dev Module
- `esp32:esp32:nodemcu-32s` - NodeMCU-32S
- `esp32:esp32:esp32-c3-devkitm-1` - ESP32-C3 DevKitM-1

### Arduino AVR Boards
- `arduino:avr:uno` - Arduino Uno
- `arduino:avr:leonardo` - Arduino Leonardo  
- `arduino:avr:mega` - Arduino Mega 2560
- `arduino:avr:nano` - Arduino Nano