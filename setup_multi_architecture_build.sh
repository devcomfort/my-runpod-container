#!/bin/bash

# This script sets up the environment for multi-architecture Docker builds.
# It assumes that Docker is already installed and running.
# It installs buildx if not present, sets up the emulator, creates a buildx builder instance,
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

# Check if buildx is installed
if ! docker buildx version >/dev/null 2>&1; then
    echo "Installing buildx..."
    wget https://github.com/docker/buildx/releases/download/v0.11.2/buildx-v0.11.2.linux-amd64
    check_command
    mkdir -p ~/.docker/cli-plugins
    mv buildx-v0.11.2.linux-amd64 ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    check_command
else
    echo "buildx is already installed."
fi

# Install emulator
echo "Installing emulator..."
docker run --privileged --rm tonistiigi/binfmt --install all
check_command

# Create buildx builder instance
echo "Creating buildx builder instance..."
docker buildx create --name multiarch-builder --bootstrap
check_command
docker buildx use multiarch-builder
check_command

# Verify setup
echo "Verifying setup..."
platforms=$(docker buildx inspect multiarch-builder | grep "Platforms:" | sed 's/Platforms: //')
echo "Supported platforms: $platforms"
if echo "$platforms" | grep -q ","; then
    echo "Multi-architecture setup is complete."
else
    echo "Multi-architecture setup might not be complete. Check the installation."
fi