#!/bin/bash

# This script sets up the environment for multi-architecture Docker builds.
# It assumes that Docker is already installed and running.
# It checks for buildx availability, sets up the emulator, creates a buildx builder instance,
# and verifies the setup by checking supported platforms.
# Note: This script requires root privileges for certain commands (e.g., installing the emulator).
# Run this script as root or with sudo.

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: Command failed."
        exit 1
    fi
}

# Check if Docker is installed
if ! command -v docker >/dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker version
docker_version=$(docker --version | awk '{print $3}' | cut -d',' -f1)
echo "Detected Docker version: $docker_version"

# Function to compare versions
version_ge() {
    # $1: current version, $2: minimum required version
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if ! version_ge "$docker_version" "19.03"; then
    echo "Error: Docker version must be 19.03 or higher."
    exit 1
else
    echo "Docker version $docker_version is sufficient."
fi

# Check if buildx is functional
# NOTE: Docker 19.03 and later include buildx by default. Manual installation is only needed if it's missing or not functional.
# If buildx is not functional, consider checking for the latest version at https://github.com/docker/buildx/releases and updating the installation command accordingly.
if ! docker buildx version >/dev/null 2>&1; then
    echo "Warning: buildx is not functional despite Docker version $docker_version."
    echo "Installing buildx manually..."
    wget https://github.com/docker/buildx/releases/download/v0.22.0/buildx-v0.22.0.linux-amd64
    check_command
    mkdir -p ~/.docker/cli-plugins
    mv buildx-v0.22.0.linux-amd64 ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    check_command
else
    echo "buildx is already functional."
fi

# Install emulator for multi-architecture support
# NOTE: The emulator (binfmt_misc) enables running non-native architectures via QEMU. Requires privileged access.
echo "Installing emulator..."
docker run --privileged --rm tonistiigi/binfmt --install all
check_command

# Create and configure buildx builder instance
# NOTE: 'multiarch-builder' is a custom builder name. '--bootstrap' ensures it's ready to use immediately.
echo "Creating buildx builder instance..."
docker buildx create --name multiarch-builder --bootstrap
check_command
docker buildx use multiarch-builder
check_command

# Verify setup by checking supported platforms
# NOTE: Multiple platforms (e.g., linux/amd64, linux/arm64) indicate successful multi-arch setup.
echo "Verifying setup..."
platforms=$(docker buildx inspect multiarch-builder | grep "Platforms:" | sed 's/Platforms: //')
echo "Supported platforms: $platforms"
if echo "$platforms" | grep -q ","; then
    echo "Multi-architecture setup is complete."
else
    echo "Multi-architecture setup might not be complete. Check the installation."
fi