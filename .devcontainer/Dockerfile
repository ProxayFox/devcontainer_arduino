ARG VARIANT
FROM mcr.microsoft.com/vscode/devcontainers/cpp:0-${VARIANT}

ARG ARDUINO_CLI_VERSION
ARG USER_NAME
ARG DIALOUT_GID=20  # Fallback if not overridden at build time
ARG PACKAGE_URL=""
ARG PLATFORM=""
ARG REMOTE_MODE="false"
ARG REMOTE_HOST="localhost"
ARG REMOTE_PORT="5000"

RUN apt update \
    && apt install -y \
    git \
    bash-completion \
    curl \
    ca-certificates \
    tar \
    gzip \
    jq \
    socat

# Configure dialout group mapping without external envfile.
# If a group already has the target GID, reuse it; otherwise create one.
RUN set -eu; \
    DIALOUT_GID_CLEAN="${DIALOUT_GID}"; \
    if ! printf '%s' "${DIALOUT_GID_CLEAN}" | grep -Eq '^[0-9]+$'; then \
        echo "Provided DIALOUT_GID='${DIALOUT_GID_CLEAN}' is not numeric; falling back to 20"; \
        DIALOUT_GID_CLEAN=20; \
    fi; \
    echo "Configuring dialout GID=${DIALOUT_GID_CLEAN}"; \
    if getent group "${DIALOUT_GID_CLEAN}" >/dev/null; then \
        HOST_DIALOUT_GROUP="$(getent group "${DIALOUT_GID_CLEAN}" | cut -d: -f1)"; \
    else \
        HOST_DIALOUT_GROUP=hostdialout; \
        groupadd -g "${DIALOUT_GID_CLEAN}" "${HOST_DIALOUT_GROUP}"; \
    fi; \
    usermod -a -G "${HOST_DIALOUT_GROUP}" "${USER_NAME}"; \
    echo "alias ll='ls -ltr'" >> /home/$USER_NAME/.bashrc; \
    echo ". /usr/share/bash-completion/completions/git" >> /home/$USER_NAME/.bashrc

# Install Arduino CLI (supports version pin or 'latest')
RUN set -eu; \
    INSTALL_VERSION="${ARDUINO_CLI_VERSION}"; \
    if [ "${INSTALL_VERSION}" = "latest" ]; then \
        curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh; \
    else \
        curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh -s -- --version "${INSTALL_VERSION}"; \
    fi; \
    mv bin/arduino-cli /usr/local/bin/arduino-cli; \
    rmdir bin || true; \
    arduino-cli version

# Initialize Arduino CLI configuration, install cores, and update index
# Run as root initially to set up system-wide config and cores
# '--config-file' ensures we use a predictable location
# '--additional-urls' adds additional board manager sources (e.g., ESP8266)
RUN mkdir -p /home/${USER_NAME}/.arduino15 \
    && arduino-cli config init --overwrite --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml \
    && if [ -n "${PACKAGE_URL}" ]; then \
        arduino-cli config set --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml board_manager.additional_urls "${PACKAGE_URL}"; \
    fi \
    && arduino-cli core update-index --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml \
    && arduino-cli core install arduino:avr --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml \
    && if [ -n "${PLATFORM}" ]; then \
        arduino-cli core install "${PLATFORM}" --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml; \
    fi \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.arduino15

# Set the default user
USER $USER_NAME

# Setup Arduino environment for user (update index again as user)
RUN arduino-cli core update-index --config-file /home/${USER_NAME}/.arduino15/arduino-cli.yaml

# Set environment variables for Arduino remote configuration
ENV REMOTE_MODE=${REMOTE_MODE}
ENV REMOTE_HOST=${REMOTE_HOST}
ENV REMOTE_PORT=${REMOTE_PORT}

LABEL desccription="Image based on Debuan providing Arduino build and debug environment"

# Project specific section
# ========================

# Install any extern libraries here. Example:
# Install LiquidCrystal I2C library
# RUN arduino-cli lib install "LiquidCrystal I2C"
