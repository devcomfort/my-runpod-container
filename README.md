# My RunPod Container

**Personal development environment containers optimized for RunPod platform.**

This repository contains customized Docker containers for personal development workflows on RunPod. Built on Ubuntu with comprehensive development tools, these containers provide a complete environment for multi-language development, machine learning, and research projects.

## 🚀 Features

### **Base Development Environment**
- **Multiple Python Versions** — Python 3.9 through 3.13 installed and ready to use, with 3.10 as the default
- **Comprehensive Toolchain** — Go, Rust, Node.js (via nvm), GitHub CLI, and essential development tools
- **Smart Workspace Setup** — Pre-configured directory structure with optimized cache locations
- **Ready-to-use Jupyter Environment** — JupyterLab with widgets and extensions
- **SSH & Web Services** — SSH access and nginx reverse proxy for web services

### **Development Tools Included**
- **Languages**: Python (3.9-3.13), Go, Rust, Node.js/TypeScript
- **Package Managers**: pip, uv, rye, npm/yarn (via nvm), cargo
- **CLI Tools**: git, gh (GitHub CLI), dvc, lefthook, rust-just
- **System Tools**: htop, iftop, tree, nano, vim, tmux, ffmpeg
- **Build Tools**: build-essential, cmake, make, gfortran

### **Hardware Support**
- **CPU**: Ubuntu 20.04, 22.04, 24.04
- **NVIDIA GPU**: CUDA 12.4.1 through 12.9.0 support
- **AMD GPU**: ROCm 6.4.1 with PyTorch integration

## 📋 Available Images

### CPU & CUDA Images
Choose from multiple Ubuntu and CUDA combinations:

#### Operating Systems:
- Ubuntu 20.04: `my-runpod:latest`, `my-runpod:ubuntu2004`
- Ubuntu 22.04: `my-runpod:ubuntu2204`, `my-runpod:jammy`
- Ubuntu 24.04: `my-runpod:ubuntu2404`, `my-runpod:noble`

#### CUDA Versions:
- **CUDA 12.4.1**: Ubuntu 20.04, 22.04
- **CUDA 12.5.1**: Ubuntu 20.04, 22.04  
- **CUDA 12.6.3**: Ubuntu 20.04, 22.04, 24.04
- **CUDA 12.8.1**: Ubuntu 20.04, 22.04, 24.04
- **CUDA 12.9.0**: Ubuntu 20.04, 22.04, 24.04

### ROCm Images (AMD GPU)
AMD GPU-accelerated images with PyTorch pre-installed:

- **ROCm 6.4.1** with PyTorch 2.5.1, 2.6.0, 2.7.0
- **Ubuntu versions**: 22.04 and 24.04
- **Python versions**: 3.10 and 3.12

Perfect for AMD GPU workloads without ROCm setup complexity.

## 🔧 Building Containers

This repository uses Docker Buildx and [bake files](https://docs.docker.com/build/bake/) for efficient builds.

### Quick Start

```bash
# Build CPU/CUDA images
./bake.sh base

# Build specific target
./bake.sh base cuda-ubuntu2204-1263

# Build and load to local Docker
./bake.sh base --load

# Build ROCm images
./bake.sh rocm
```

### Build Options

```bash
# CPU only
./bake.sh base cpu

# All CUDA variants
./bake.sh base cuda-matrix

# Specific ROCm target
./bake.sh rocm rocm641-ubuntu2204-pytorch260
```

## 🌐 Port Configuration

### Core Services
- **SSH**: Port 22 (always enabled)
- **Jupyter Lab**: Port 8888 (enabled with `JUPYTER_PASSWORD`)
- **Filebrowser**: Port 4040 → Proxied at 4041 (toggleable)
- **HTTP Server**: Port 8088 → Proxied at 8089 (toggleable)

### Development Ports (Reserved)
- **Code Server**: Port 8081 → 8080 (VS Code in browser)
- **VS Code Server**: Port 8001 → 8000 (VS Code remote)
- **Generic Backend 1**: Port 5001 → 5000
- **Generic Backend 2**: Port 6001 → 6000  
- **Generic Backend 3**: Port 7001 → 7000
- **Generic Backend 4**: Port 9001 → 9000

### Specialized Ports (Available)
- **Oobabooga**: Port 7861 → 7860
- **InvokeAI**: Port 9091 → 9090
- **Stable Diffusion/ComfyUI**: Port 3001 → 3000
- **RunPod CLI API**: Port 7270 → 7271

## ⚙️ Service Configuration

### Environment Variables
- `JUPYTER_PASSWORD`: Set to enable Jupyter on port 8888
- `ENABLE_FILEBROWSER=1`: Start filebrowser on 4040 (default: enabled)
- `ENABLE_HTTP_SERVER=1`: Start temporary http.server on 8088 (default: disabled)
- `PUBLIC_KEY`: SSH public key for remote access (SSH always enabled)

### Usage Notes
- Left side (higher port) = External access through nginx proxy
- Right side (lower port) = Internal service port
- All services run behind nginx reverse proxy for security
- Reserve ports allow multiple development services simultaneously

## 🏗️ Architecture

### Directory Structure
```
├── builds/                # Build configurations
│   ├── base/              # CPU & CUDA images
│   ├── rocm/              # AMD GPU images  
│   └── shared/            # Shared version definitions
├── bake.sh                # Build script
├── README.md              # Main documentation
└── RUNPOD.md              # RunPod platform guide
```

### Version Management
Version compatibility and build targets are centralized in `builds/shared/versions.hcl`. This file defines:
- Ubuntu version matrix
- CUDA version compatibility  
- Build target combinations

## 🔧 Environment Variables Setup

### Runtime Environment Variables (Container)
These variables control container behavior when running:

| Variable | Purpose | Default | Where to Set |
|----------|---------|---------|--------------|
| `JUPYTER_PASSWORD` | Enable Jupyter Lab on port 8888 | Not set (disabled) | Docker run `-e` or RunPod template |
| `ENABLE_FILEBROWSER` | Start filebrowser service | `1` (enabled) | Docker run `-e` or RunPod template |
| `ENABLE_HTTP_SERVER` | Start Python http.server | `0` (disabled) | Docker run `-e` or RunPod template |
| `PUBLIC_KEY` | SSH public key for access | Not set | Docker run `-e` or RunPod template* |
| `TZ` | Container timezone | `Asia/Seoul` | Build-time (Dockerfile)* |

**How to get values:**
- `PUBLIC_KEY`: `cat ~/.ssh/id_rsa.pub` (your SSH public key)
- `JUPYTER_PASSWORD`: Any secure password you choose
- `ENABLE_*`: Set to `1` (enable) or `0` (disable)

**RunPod Platform Notes:**
- **`PUBLIC_KEY`**: ✅ **자동 주입됨** - 계정 설정의 SSH 키들이 자동으로 주입
- **`TZ`**: ❌ **주입되지 않음** - 컨테이너 기본값(Asia/Seoul) 사용, 템플릿에서 오버라이드 가능
- **추가 환경변수**: `RUNPOD_POD_ID`, `RUNPOD_API_KEY`, `RUNPOD_TCP_PORT_22` 등 15개+ 변수 자동 주입
- 상세 정보: [RUNPOD.md](./RUNPOD.md) 참조

### Build Environment Variables
These variables control the build process:

| Variable | Purpose | Default | Where to Set |
|----------|---------|---------|--------------|
| `RELEASE_VERSION` | Image version tag | `0.7.0` | `builds/shared/versions.hcl` |
| `BASE_IMAGE` | Base Ubuntu/CUDA image | Varies by target | Docker bake files |

### GitHub Actions Secrets
Required for automated builds and deployments:

| Secret | Purpose | How to Get | Where to Set |
|--------|---------|------------|--------------|
| `DOCKERHUB_USERNAME` | Docker Hub login | Your Docker Hub username | GitHub → Settings → Secrets |
| `DOCKERHUB_TOKEN` | Docker Hub authentication | [Create access token](https://hub.docker.com/settings/security) | GitHub → Secrets and variables → Actions |

**Setting up GitHub Secrets:**
1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name above

**Getting Docker Hub Token:**
1. Log in to [Docker Hub](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Name: `github-actions-my-runpod-container`
5. Permissions: **Read, Write, Delete**
6. Copy the generated token (save it securely!)

### Local Development Environment Variables
For local builds and development:

```bash
# Optional: Override default versions
export RELEASE_VERSION="dev-$(git branch --show-current)"

# Optional: Custom Docker registry
export DOCKER_REGISTRY="your-registry.com"

# Build with custom version
./bake.sh base --set "*.tags=my-runpod:${RELEASE_VERSION}"
```

### RunPod Platform Configuration

For detailed RunPod platform setup, see [RUNPOD.md](./RUNPOD.md).

**Quick Setup:**
```bash
# RunPod Template Environment Variables
JUPYTER_PASSWORD=your-secure-password
ENABLE_FILEBROWSER=1
ENABLE_HTTP_SERVER=0
```

**Key Points:**
- SSH keys can be managed via RunPod account settings (recommended)
- RunPod automatically handles port mapping
- Platform-specific environment variables are auto-injected

## 🚀 Getting Started

1. **Set up environment variables** (see above section)
2. **Choose your image** based on hardware (CPU/NVIDIA/AMD)
3. **Build locally** or pull from registry
4. **Configure services** via runtime environment variables
5. **Access via SSH** or web interfaces (Jupyter, VS Code, etc.)

### Example Usage

```bash
# 1. Build and run CPU image
./bake.sh base cpu-ubuntu2204 --load

# 2. Run with all services enabled
docker run -it --rm \
  -p 22:22 -p 8888:8888 -p 8081:8081 -p 4041:4041 -p 8089:8089 \
  -e JUPYTER_PASSWORD="secure-password-123" \
  -e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  -e ENABLE_FILEBROWSER=1 \
  -e ENABLE_HTTP_SERVER=1 \
  runpod/base:0.7.0-ubuntu2204

# 3. Access services
# - SSH: ssh root@localhost -p 22
# - Jupyter: http://localhost:8888 (password: secure-password-123)
# - Filebrowser: http://localhost:4041
# - HTTP Server: http://localhost:8089
# - Code Server: http://localhost:8081 (if installed)

# 4. RunPod Template Environment Variables
# See RUNPOD.md for detailed RunPod configuration
# JUPYTER_PASSWORD=your-secure-password
# ENABLE_FILEBROWSER=1
# ENABLE_HTTP_SERVER=0
```

## 📚 References

### Platform Guides
- **[RUNPOD.md](./RUNPOD.md)** - Detailed RunPod platform configuration and troubleshooting

### Development Tools
- [Rye (Python 툴체인)](https://rye.astral.sh/) - Python 프로젝트 관리
- [uv (pip 대체)](https://github.com/astral-sh/uv) - 빠른 Python 패키지 설치
- [WebInstall](https://webinstall.dev/) - 개발 도구 간편 설치
- [NVM](https://github.com/nvm-sh/nvm) - Node.js 버전 관리

### Container & Docker
- [Docker Buildx Bake](https://docs.docker.com/build/bake/) - 멀티 플랫폼 빌드
- [S6-overlay](https://github.com/just-containers/s6-overlay) - 컨테이너 프로세스 관리

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

This is a personal development environment, but feel free to fork and adapt for your own needs!