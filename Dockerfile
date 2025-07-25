# ============================================================================
# Multi-stage Dockerfile for Personal RunPod Environment
# Optimized for build size, speed, and storage efficiency
# ============================================================================

# === Build Arguments ===
ARG BASE_IMAGE
ARG BASE_RELEASE_VERSION

# ============================================================================
# 개발 도구 버전 관리 (2024년 12월 기준 최신 안정 버전)
# ============================================================================
ARG GO_VERSION="1.23.4"
ARG TINYGO_VERSION="0.38.0"
ARG GH_VERSION="2.76.1"
ARG VS_CODE_VERSION="latest"
ARG INSTALL_SLURM="true"

# ============================================================================
# Stage 1: Base System Setup
# ============================================================================
FROM ${BASE_IMAGE} as base-system

# === Environment Setup ===
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    VSCODE_SERVE_MODE=remote \
    BASE_RELEASE_VERSION=${BASE_RELEASE_VERSION}

WORKDIR /

# === APT Mirror Optimization & System Packages Installation ===
RUN set -eux; \
    # APT 미러 서버 최적화 (한국)
    sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' /etc/apt/sources.list && \
    \
    # APT 설정 최적화
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/02retries && \
    \
    # 시스템 업데이트 및 필수 패키지 설치 (한 번에 진행)
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        # Build tools
        software-properties-common \
        build-essential \
        make \
        cmake \
        gfortran \
        # Development libraries
        libblas-dev \
        liblapack-dev \
        libatlas-base-dev \
        libffi-dev \
        libhdf5-serial-dev \
        libssl-dev \
        # Media processing
        ffmpeg \
        libavcodec-dev \
        libavfilter-dev \
        libavformat-dev \
        libavutil-dev \
        libjpeg-dev \
        libpng-dev \
        libpostproc-dev \
        libswresample-dev \
        libswscale-dev \
        libtiff-dev \
        libv4l-dev \
        libx264-dev \
        libxext6 \
        libxrender-dev \
        libxvidcore-dev \
        # System utilities
        git \
        curl \
        wget \
        unzip \
        zip \
        tree \
        htop \
        iftop \
        nano \
        # Network and services
        nginx \
        openssh-server \
        # File systems
        cifs-utils \
        nfs-common \
        zstd \
        # GUI support
        libsm6 \
        expect \
        gnome-keyring \
        ca-certificates \
        tzdata && \
    \
    # 캐시 정리
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    # 불필요한 시스템 파일 정리
    find /usr/share/doc -depth -type f ! -name copyright | xargs rm || true && \
    find /usr/share/man -type f | xargs rm || true && \
    find /usr/share/groff -type f | xargs rm || true && \
    find /usr/share/info -type f | xargs rm || true && \
    find /usr/share/lintian -type f | xargs rm || true && \
    find /usr/share/linda -type f | xargs rm || true

# ============================================================================
# Stage 2: Development Tools Builder
# ============================================================================
FROM base-system as dev-tools-builder

# === Development Tools Installation (Parallel where possible) ===
RUN set -eux; \
    # Create temporary directory for downloads
    mkdir -p /tmp/downloads && \
    cd /tmp/downloads && \
    \
    # VS Code Server 설치
    curl -fsSL https://code-server.dev/install.sh | bash && \
    \
    # 병렬 다운로드를 위한 백그라운드 프로세스 시작
    # Rust 설치
    (curl -sSf https://sh.rustup.rs | sh -s -- -y) & \
    RUST_PID=$! && \
    \
    # Python Rye 설치 
    (curl -sSf https://rye.astral.sh/get | RYE_HOME="/root/.rye" RYE_VERSION="latest" RYE_INSTALL_OPTION="--yes" bash) & \
    RYE_PID=$! && \
    \
    # Go 설치 (webinstall 대신 직접 다운로드)
    GO_VERSION=$(echo $GO_VERSION | sed 's/v//') && \
    GO_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -sSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o go.tar.gz & \
    GO_PID=$! && \
    \
    # GitHub CLI 설치 (webinstall 대신 직접 다운로드)
    GH_VERSION=$(echo $GH_VERSION | sed 's/v//') && \
    GH_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -sSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" -o gh.tar.gz & \
    GH_PID=$! && \
    \
    # Ollama 설치 (백그라운드)
    (curl -fsSL https://ollama.com/install.sh | bash) & \
    OLLAMA_PID=$! && \
    \
    # 모든 백그라운드 작업 완료 대기
    wait $RUST_PID && \
    wait $RYE_PID && \
    wait $GO_PID && \
    wait $GH_PID && \
    wait $OLLAMA_PID && \
    \
    # Go 설치 완료
    tar -C /usr/local -xzf go.tar.gz && \
    \
    # GitHub CLI 설치 완료
    tar -xzf gh.tar.gz && \
    cp gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh /usr/local/bin/ && \
    \
    # TinyGo 설치 (Go가 설치된 후)
    TINYGO_VERSION=$(echo $TINYGO_VERSION | sed 's/v//') && \
    TINYGO_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -sSL "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-${TINYGO_ARCH}.tar.gz" -o tinygo.tar.gz && \
    tar -C /usr/local -xzf tinygo.tar.gz && \
    \
    # 환경 변수 설정
    echo 'export PATH="/usr/local/go/bin:$PATH"' >> /root/.profile && \
    echo 'export PATH="/usr/local/tinygo/bin:$PATH"' >> /root/.profile && \
    echo 'source "$HOME/.cargo/env"' >> /root/.profile && \
    echo 'source /root/.rye/env' >> /root/.profile && \
    \
    # 임시 파일 정리
    cd / && rm -rf /tmp/downloads

# === HPC & Workflow Tools Installation ===
RUN set -eux; \
    # PATH 로드
    source /root/.profile && \
    \
    # Rust 도구 설치 (memlimit)
    source "$HOME/.cargo/env" && \
    cargo install memlimit && \
    \
    # Python 도구 설치
    source /root/.rye/env && \
    rye install jupyterlab && \
    rye install magic-wormhole && \
    rye install invoke && \
    \
    # Slurm 클라이언트 도구 설치 (선택적)
    if [ "${INSTALL_SLURM:-true}" = "true" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            slurm-client \
            slurm-wlm-basic-plugins && \
        \
        # Slurm 기본 설정 디렉토리 생성
        mkdir -p /etc/slurm /var/log/slurm /var/spool/slurm && \
        \
        # 기본 slurm.conf 템플릿 생성 (외부 클러스터 연결용)
        cat > /etc/slurm/slurm.conf.template << 'EOF'
# Slurm Configuration Template
# 이 파일을 /etc/slurm/slurm.conf로 복사하고 실제 클러스터 정보로 수정하세요
# 
# ClusterName=YOUR_CLUSTER_NAME
# ControlMachine=YOUR_CONTROL_NODE
# ControlAddr=YOUR_CONTROL_IP
# 
# Example:
# ClusterName=research-cluster
# ControlMachine=slurm-controller
# ControlAddr=10.0.0.100
# SlurmUser=slurm
# SlurmdUser=root
# StateSaveLocation=/var/spool/slurm/ctld
# SlurmdSpoolDir=/var/spool/slurm/d
# SwitchType=switch/none
# MpiDefault=none
# ProctrackType=proctrack/pgid
# ReturnToService=2
# TaskPlugin=task/none
# 
# # Node and Partition Configuration (예시)
# NodeName=compute[001-010] CPUs=4 State=UNKNOWN
# PartitionName=debug Nodes=compute[001-010] Default=YES MaxTime=INFINITE State=UP
EOF
        \
        echo "✅ Slurm client tools installed successfully" && \
        echo "💡 Configure /etc/slurm/slurm.conf to connect to your Slurm cluster"; \
    else \
        echo "⏭️  Slurm installation skipped (INSTALL_SLURM=false)"; \
    fi && \
    \
    # Cargo 캐시 정리 (cargo-cache가 설치되어 있다면)
    if command -v cargo-cache >/dev/null 2>&1; then \
        cargo cache --autoclean; \
    fi && \
    rm -rf ~/.cargo/registry/cache/* ~/.cargo/git/*/refs && \
    \
    # Rye 캐시 정리
    rye cache clean --all || true && \
    \
    # APT 캐시 정리 (Slurm 설치 후)
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ============================================================================
# Stage 3: Final Runtime Image
# ============================================================================
FROM base-system as final

# === Copy Development Tools from Builder ===
COPY --from=dev-tools-builder /usr/local /usr/local
COPY --from=dev-tools-builder /root/.cargo /root/.cargo
COPY --from=dev-tools-builder /root/.rye /root/.rye
COPY --from=dev-tools-builder /root/.profile /root/.profile

# === Copy Application Files ===
COPY container/src/* /usr/local/bin/
COPY container/proxy/nginx.conf /etc/nginx/nginx.conf
COPY container/proxy/readme.html /usr/share/nginx/html/readme.html
COPY README.md /usr/share/nginx/html/README.md
COPY container/scripts/post_start.sh /
COPY container/scripts/start.sh /

# === Final Configuration ===
RUN set -eux; \
    # Nginx 설정
    wget -O /tmp/init-deb.sh https://www.linode.com/docs/assets/660-init-deb.sh && \
    mv /tmp/init-deb.sh /etc/init.d/nginx && \
    chmod +x /etc/init.d/nginx && \
    /usr/sbin/update-rc.d -f nginx defaults && \
    \
    # 스크립트 권한 설정
    chmod +x /start.sh && \
    chmod +x /usr/local/bin/* && \
    \
    # 최종 정리
    rm -rf /tmp/* /var/tmp/* && \
    \
    # 환경 변수 테스트 (빌드 시 검증)
    source /root/.profile && \
    command -v cargo >/dev/null && \
    command -v rye >/dev/null && \
    command -v go >/dev/null && \
    command -v gh >/dev/null && \
    echo "All tools installed successfully"

# === Port Exposure ===
EXPOSE 22 80 443 8000 8080

# === Default Command ===
CMD ["/start.sh"]