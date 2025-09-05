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
└── README.md              # This file
```

### Version Management
Version compatibility and build targets are centralized in `builds/shared/versions.hcl`. This file defines:
- Ubuntu version matrix
- CUDA version compatibility  
- Build target combinations

## 🚀 Getting Started

1. **Choose your image** based on hardware (CPU/NVIDIA/AMD)
2. **Build locally** or pull from registry
3. **Configure services** via environment variables
4. **Access via SSH** or web interfaces (Jupyter, VS Code, etc.)

### Example Usage

```bash
# Build and run CPU image
./bake.sh base cpu-ubuntu2204 --load
docker run -it --rm \
  -p 8888:8888 -p 8081:8081 -p 4041:4041 \
  -e JUPYTER_PASSWORD=mypassword \
  -e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  my-runpod:ubuntu2204

# Access services
# - Jupyter: http://localhost:8888
# - Filebrowser: http://localhost:4041  
# - SSH: ssh root@localhost
```

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

This is a personal development environment, but feel free to fork and adapt for your own needs!