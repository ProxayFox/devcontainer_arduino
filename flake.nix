# Referance from https://github.com/bouk/arduino-nix
# But setup for devshell environment
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
    arduino-nix.url = "github:bouk/arduino-nix";
    arduino-index = {
      url = "github:bouk/arduino-indexes";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
    arduino-nix,
    arduino-index,
    ...
  }@attrs:
  let
    overlays = [
      devshell.overlays.default
      (arduino-nix.overlay)
      (arduino-nix.mkArduinoPackageOverlay (arduino-index + "/index/package_index.json"))
      (arduino-nix.mkArduinoPackageOverlay (arduino-index + "/index/package_rp2040_index.json"))
      (arduino-nix.mkArduinoLibraryOverlay (arduino-index + "/index/library_index.json"))
    ];
  in
  (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system overlays;
        };
        
        arduino-cli-wrapped = pkgs.wrapArduinoCLI {
          libraries = with pkgs.arduinoLibraries; [
            (arduino-nix.latestVersion ADS1X15)
            (arduino-nix.latestVersion Ethernet_Generic)
            (arduino-nix.latestVersion SCL3300)
            (arduino-nix.latestVersion TMCStepper)
            (arduino-nix.latestVersion pkgs.arduinoLibraries."Adafruit PWM Servo Driver Library")
          ];

          packages = with pkgs.arduinoPackages; [
            platforms.arduino.avr."1.6.23"
            platforms.rp2040.rp2040."2.3.3"
          ];
        };
      in rec {
        packages.arduino-cli = arduino-cli-wrapped;
        
        devShells.default = pkgs.devshell.mkShell {
          name = "Arduino Development Environment";
          
          packages = with pkgs; [
            arduino-cli-wrapped
            arduino
            devcontainer
            git
            gnumake
            gcc
            gdb
            minicom
            screen
            picocom
            socat
          ];
          
          commands = [
            {
              name = "uno-compile";
              help = "Compile Arduino sketch";
              command = "arduino-cli compile --fqbn arduino:avr:uno $@";
            }
            {
              name = "uno-upload";
              help = "Upload Arduino sketch to board";
              command = "arduino-cli upload --fqbn arduino:avr:uno --port /dev/ttyUSB0 $@";
            }
            {
              name = "uno-monitor";
              help = "Open serial monitor";
              command = "arduino-cli monitor --port /dev/ttyUSB0";
            }
            {
              name = "uno-boards";
              help = "List available boards";
              command = "arduino-cli board list";
            }
            {
              name = "uno-libs";
              help = "List installed libraries";
              command = "arduino-cli lib list";
            }
            {
              name = "uno";
              help = "runs the Arduino CLI";
              command = "arduino-cli";
            }
          ];
          
          env = [
            {
              name = "ARDUINO_DIRECTORIES_DATA";
              value = ".arduino15";
            }
            {
              name = "ARDUINO_DIRECTORIES_DOWNLOADS";
              value = ".arduino15/staging";
            }
          ];
          
          motd = ''
            Welcome to Arduino Development Environment!
            
            Available commands:
            • uno-compile <sketch-dir> - Compile Arduino sketch
            • uno-upload <sketch-dir>  - Upload to board
            • uno-monitor              - Open serial monitor
            • uno-boards               - List available boards
            • uno-libs                 - List installed libraries
            • uno                      - runs the Arduino CLI

            Your Arduino CLI is pre-configured with libraries:
            • ADS1X15, Ethernet_Generic, SCL3300
            • TMCStepper, Adafruit PWM Servo Driver
            
            Supported platforms:
            • Arduino AVR (1.6.23)
            • Raspberry Pi Pico RP2040 (2.3.3)
          '';
        };
      }
    ));
}