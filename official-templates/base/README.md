<h1>Runpod Base</h1>

**Essential foundation for machine learning workflows.**

Runpod Base images are designed to be lightweight but flexible—supporting a wide range of user workloads without overwhelming choice when building your own images. Whether you're prototyping a new ML model, setting up a development environment, or deploying a production workload, these images provide the essential foundation you need to get started fast.

**What makes these essential:**
- **Ready-to-use Jupyter Environment** — Both Notebook and JupyterLab with widgets and extensions (optional - can be disabled by not setting `JUPYTER_PASSWORD`)
- **Multiple Python Versions** — Python 3.9 through 3.13 installed and ready to use, with 3.10 as the default
- **Smart Workspace Setup** — Pre-configured directory structure with optimized cache locations for faster package installs
- **Developer Tools** — SSH access for remote development and NGINX server for web services. Optional reserve ports for code-server (8081→8080), http.server (8089→8088), filebrowser (4041→4040), and generic backends (5001→5000 / 6001→6000 / 7001→7000 / 9001→9000).
- **ML-Ready Libraries** — Core dependencies for scientific computing, image processing, and machine learning workflows

**Choose your combination:**
- **Ubuntu versions:** 20.04, 22.04, or 24.04
- **CUDA versions:** 12.4.1 through 12.9.0 for GPU acceleration
- **Optimized Performance:** Efficiently configured environment variables and cache directories

Perfect for immediate development and experimenting, or as the foundation for more specialized containers.

*Need something more specialized? Check out our other templates in the `official-templates` directory for ROCm support, PyTorch, and other ML frameworks.*

<div class="base-images">

## Generated Images

### Operating Systems:
- Ubuntu 20.04:
    - `runpod/base:0.7.0`
    - `runpod/base:0.7.0-ubuntu2004`
- Ubuntu 22.04:
    - `runpod/base:0.7.0-ubuntu2204`
    - `runpod/base:0.7.0-jammy`
- Ubuntu 24.04:
    - `runpod/base:0.7.0-ubuntu2404`
    - `runpod/base:0.7.0-noble`

### CUDA Versions:
- 12.4.1:
    - Ubuntu 20.04:
        - `runpod/base:0.7.0-cuda1241`
        - `runpod/base:0.7.0-cuda1241-ubuntu2004`
        - `runpod/base:0.7.0-focal-cuda1241`
    - Ubuntu 22.04:
        - `runpod/base:0.7.0-cuda1241`
        - `runpod/base:0.7.0-cuda1241-ubuntu2204`
        - `runpod/base:0.7.0-jammy-cuda1241`
- 12.5.1:
    - Ubuntu 20.04:
        - `runpod/base:0.7.0-cuda1251`
        - `runpod/base:0.7.0-cuda1251-ubuntu2004`
        - `runpod/base:0.7.0-focal-cuda1251`
    - Ubuntu 22.04:
        - `runpod/base:0.7.0-cuda1251`
        - `runpod/base:0.7.0-cuda1251-ubuntu2204`
        - `runpod/base:0.7.0-jammy-cuda1251`
- 12.6.3:
    - Ubuntu 20.04:
        - `runpod/base:0.7.0-cuda1263`
        - `runpod/base:0.7.0-cuda1263-ubuntu2004`
        - `runpod/base:0.7.0-focal-cuda1263`
    - Ubuntu 22.04:
        - `runpod/base:0.7.0-cuda1263`
        - `runpod/base:0.7.0-cuda1263-ubuntu2204`
        - `runpod/base:0.7.0-jammy-cuda1263`
    - Ubuntu 24.04:
        - `runpod/base:0.7.0-cuda1263`
        - `runpod/base:0.7.0-cuda1263-ubuntu2404`
        - `runpod/base:0.7.0-noble-cuda1263`
- 12.8.1:
    - Ubuntu 20.04:
        - `runpod/base:0.7.0-cuda1281`
        - `runpod/base:0.7.0-cuda1281-ubuntu2004`
        - `runpod/base:0.7.0-focal-cuda1281`
    - Ubuntu 22.04:
        - `runpod/base:0.7.0-cuda1281`
        - `runpod/base:0.7.0-cuda1281-ubuntu2204`
        - `runpod/base:0.7.0-jammy-cuda1281`
    - Ubuntu 24.04:
        - `runpod/base:0.7.0-cuda1281`
        - `runpod/base:0.7.0-cuda1281-ubuntu2404`
        - `runpod/base:0.7.0-noble-cuda1281`
- 12.9.0:
    - Ubuntu 20.04:
        - `runpod/base:0.7.0-cuda1290`
        - `runpod/base:0.7.0-cuda1290-ubuntu2004`
        - `runpod/base:0.7.0-focal-cuda1290`
    - Ubuntu 22.04:
        - `runpod/base:0.7.0-cuda1290`
        - `runpod/base:0.7.0-cuda1290-ubuntu2204`
        - `runpod/base:0.7.0-jammy-cuda1290`
    - Ubuntu 24.04:
        - `runpod/base:0.7.0-cuda1290`
        - `runpod/base:0.7.0-cuda1290-ubuntu2404`
        - `runpod/base:0.7.0-noble-cuda1290`
</div>

## Service Toggles

- `JUPYTER_PASSWORD`: set to enable Jupyter on 8888
- `ENABLE_FILEBROWSER=1`: start filebrowser on 4040 (proxied at 4041)
- `ENABLE_HTTP_SERVER=1`: start temporary http.server on 8088 (proxied at 8089)

## Port Configuration

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

### Usage Notes
- Left side (higher port) = External access through nginx proxy
- Right side (lower port) = Internal service port
- All services run behind nginx reverse proxy for security
- Reserve ports allow multiple development services simultaneously

