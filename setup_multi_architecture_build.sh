#!/bin/bash

# This script sets up the environment for multi-architecture Docker builds.
# It assumes that Docker is already installed and running.
# It checks for buildx availability, sets up the emulator, creates a buildx builder instance,
# and verifies the setup by checking supported platforms.
# Note: This script requires root privileges for certain commands (e.g., installing the emulator).
# Run this script as root or with sudo.

set -euo pipefail  # Improved error handling

# Docker Buildx 버전 설정 (개발자 로컬 도구 - 별도 관리)
# 참고: 이 도구는 개발자가 직접 관리해야 하는 로컬 환경 도구입니다.

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        log_error "Command failed."
        exit 1
    fi
}

# Platform detection function
detect_platform() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $arch in
        x86_64|amd64)
            PLATFORM_ARCH="amd64"
            ;;
        aarch64|arm64)
            PLATFORM_ARCH="arm64"
            ;;
        armv7l)
            PLATFORM_ARCH="arm"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    case $os in
        linux)
            PLATFORM_OS="linux"
            ;;
        darwin)
            PLATFORM_OS="darwin"
            ;;
        *)
            log_error "Unsupported OS: $os"
            exit 1
            ;;
    esac
    
    PLATFORM="${PLATFORM_OS}-${PLATFORM_ARCH}"
    log_info "Detected platform: $PLATFORM"
}

# Check if running in CI environment
is_ci_environment() {
    [[ "${CI:-false}" == "true" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]
}

# Check if Docker is installed
check_docker() {
if ! command -v docker >/dev/null; then
        log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker version
docker_version=$(docker --version | awk '{print $3}' | cut -d',' -f1)
    log_info "Detected Docker version: $docker_version"

# Function to compare versions
version_ge() {
    # $1: current version, $2: minimum required version
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if ! version_ge "$docker_version" "19.03"; then
        log_error "Docker version must be 19.03 or higher."
    exit 1
else
        log_info "Docker version $docker_version is sufficient."
fi
}

# Install or check buildx
setup_buildx() {
# Check if buildx is functional
    if docker buildx version >/dev/null 2>&1; then
        log_info "buildx is already functional."
        return 0
    fi
    
    log_warn "buildx is not functional despite Docker version $docker_version."
    log_info "Installing buildx manually..."
    
    # Detect platform for buildx download
    detect_platform
    
          # Docker Buildx 버전 설정 (개발자 로컬 도구)
      BUILDX_MIN_VERSION="v0.25.0"
      BUILDX_RECOMMENDED_VERSION="v0.26.1"
      
      # 현재 설치된 버전 체크
      CURRENT_BUILDX=""
      if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
          CURRENT_BUILDX=$(docker buildx version | head -1 | sed 's/.*v\([0-9.]*\).*/v\1/')
          log_info "현재 설치된 Buildx 버전: $CURRENT_BUILDX"
          
          # 최소 버전 체크 (간단한 문자열 비교)
          if [[ "$CURRENT_BUILDX" < "$BUILDX_MIN_VERSION" ]]; then
              log_warn "현재 Buildx 버전($CURRENT_BUILDX)이 최소 요구 버전($BUILDX_MIN_VERSION)보다 낮습니다"
              BUILDX_VERSION="$BUILDX_RECOMMENDED_VERSION"
          else
              log_info "현재 Buildx 버전이 요구사항을 만족합니다. 기존 버전 사용"
              return 0
          fi
      else
          log_info "Buildx가 설치되지 않음. 권장 버전($BUILDX_RECOMMENDED_VERSION) 설치"
          BUILDX_VERSION="$BUILDX_RECOMMENDED_VERSION"
      fi
      
      # Construct download URL
    BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${PLATFORM}"
    
    log_info "Downloading buildx from: $BUILDX_URL"
    
    # Create plugin directory
    mkdir -p ~/.docker/cli-plugins
    
    # Download with retry logic
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if wget -q "$BUILDX_URL" -O ~/.docker/cli-plugins/docker-buildx; then
            break
        elif curl -sSL "$BUILDX_URL" -o ~/.docker/cli-plugins/docker-buildx; then
            break
        else
            retry_count=$((retry_count + 1))
            log_warn "Download attempt $retry_count failed. Retrying..."
            sleep 2
        fi
    done
    
    if [ $retry_count -eq $max_retries ]; then
        log_error "Failed to download buildx after $max_retries attempts"
        exit 1
    fi
    
    chmod +x ~/.docker/cli-plugins/docker-buildx
    check_command
    
    # Verify installation
    if docker buildx version >/dev/null 2>&1; then
        log_info "buildx installation successful."
else
        log_error "buildx installation failed."
        exit 1
fi
}

# Install emulator for multi-architecture support
setup_emulator() {
    # Skip emulator setup in CI if already configured
    if is_ci_environment && docker buildx inspect 2>/dev/null | grep -q "linux/arm64"; then
        log_info "Multi-architecture support already configured in CI environment."
        return 0
    fi
    
    log_info "Installing emulator..."
    
    # Check if we need privileged access
    if ! docker run --rm --privileged tonistiigi/binfmt --install all 2>/dev/null; then
        log_warn "Failed to install emulator with privileged access."
        
        # Try alternative method for CI environments
        if is_ci_environment; then
            log_info "Trying CI-friendly emulator setup..."
            docker run --rm tonistiigi/binfmt --install all 2>/dev/null || {
                log_warn "Alternative emulator setup also failed. Continuing without full multi-arch support."
                return 0
            }
        else
            log_error "Emulator installation failed. Make sure to run with sufficient privileges."
            exit 1
        fi
    fi
    
    log_info "Emulator installation successful."
}

# Create and configure buildx builder instance
setup_builder() {
    local builder_name="multiarch-builder"
    
    # Check if builder already exists
    if docker buildx inspect "$builder_name" >/dev/null 2>&1; then
        log_info "Builder '$builder_name' already exists. Using existing builder."
        docker buildx use "$builder_name"
        return 0
    fi
    
    log_info "Creating buildx builder instance..."
    
    # Create builder with appropriate configuration
    if is_ci_environment; then
        # In CI, use simpler configuration
        docker buildx create --name "$builder_name" --use
    else
        # Local development - full configuration
        docker buildx create --name "$builder_name" --bootstrap --use
    fi
    
check_command
    
    log_info "Builder '$builder_name' created and activated."
}

# Verify setup by checking supported platforms
verify_setup() {
    log_info "Verifying setup..."
    
    local builder_name="multiarch-builder"
    local platforms
    
    # Get supported platforms
    if platforms=$(docker buildx inspect "$builder_name" 2>/dev/null | grep "Platforms:" | sed 's/Platforms: //'); then
        log_info "Supported platforms: $platforms"
        
        # Check for multi-architecture support
if echo "$platforms" | grep -q ","; then
            log_info "✅ Multi-architecture setup is complete."
            
            # Additional verification for key platforms
            if echo "$platforms" | grep -q "linux/amd64" && echo "$platforms" | grep -q "linux/arm64"; then
                log_info "✅ Both AMD64 and ARM64 platforms supported."
            else
                log_warn "⚠️  Not all expected platforms are available."
            fi
        else
            log_warn "⚠️  Multi-architecture setup might not be complete."
            log_info "Available platform: $platforms"
        fi
    else
        log_error "Failed to inspect builder. Please check the setup manually."
        exit 1
    fi
}

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Setup failed. You may need to clean up manually:"
        log_error "  docker buildx rm multiarch-builder"
    fi
    exit $exit_code
}

# Main execution
main() {
    trap cleanup EXIT
    
    log_info "Starting multi-architecture Docker build setup..."
    
    # Detect platform first
    detect_platform
    
    # Check prerequisites
    check_docker
    
    # Setup components
    setup_buildx
    setup_emulator  
    setup_builder
    
    # Verify everything works
    verify_setup
    
    log_info "🎉 Multi-architecture Docker build setup completed successfully!"
    log_info "You can now run: docker buildx bake --file docker-bake.hcl"
}

# Run main function
main "$@"