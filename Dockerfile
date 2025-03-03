# === 베이스 이미지 설정 ===
# RunPod용 기본 베이스 이미지 설정
# 외부에서 --build-arg BASE_IMAGE=값으로 전달할 수 있음
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# === 기본 셸 및 환경 설정 ===
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# === 기본 환경 변수 설정 ===
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash
# === 개발 환경 설정 ===
ENV VSCODE_SERVE_MODE=remote

# === 버전 관리 ===
ARG BASE_RELEASE_VERSION
ENV BASE_RELEASE_VERSION=${BASE_RELEASE_VERSION}

# === 작업 디렉토리 설정 ===
WORKDIR /

# === 시스템 패키지 관리 ===
## APT 미러 서버 설정 주의사항:
## 1. 프로토콜(http/https)과 경로 끝에 파일 구분자가(/) 정확히 설정되어야 함
## 2. 잘못된 경로 설정은 apt-get이 정상적으로 작동하지 않을 수 있음
## 3. Kakao 미러 사용을 권장함
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|' /etc/apt/sources.list
RUN sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|' /etc/apt/sources.list

# === 시스템 패키지 관리 ===
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    make \
    cmake \
    gfortran \
    libblas-dev \
    liblapack-dev \
    git \
    nano \
    htop \
    nginx \
    unzip \
    zip \
    wget \
    curl \
    openssh-server \
    # Utils
    tree \
    iftop \
    # Image and Video Processing
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
    # Deep Learning Dependencies and Miscellaneous
    libatlas-base-dev \
    libffi-dev \
    libhdf5-serial-dev \
    libsm6 \
    libssl-dev \
    # File Systems and Storage
    cifs-utils \
    nfs-common \
    zstd \
    nano \
    nginx \
    tzdata \
    expect \
    gnome-keyring ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean -y

# === VS Code 서버 설정 ===
RUN curl -fsSL https://code-server.dev/install.sh | bash
# === copy scripts ===
COPY src/* /usr/local/bin/

# === webinstall.sh를 통한 유틸리티 설치 ===
# ollama
RUN curl -sS https://webi.sh/ollama | bash
# gh (GitHub CLI)
RUN curl -sS https://webi.sh/gh | bash
# golang
RUN curl -sS https://webi.sh/golang | bash
# tinygo
RUN curl -sS https://webi.sh/tinygo | bash

# === webinstall.sh로 설치한 것들 환경 변수로 동작하도록 등록 ===
RUN echo "source /root/.config/envman/PATH.env" >> /root/.profile

# === rust, cargo 설치 및 PATH 설정 ===
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source "$HOME/.cargo/env"' >> /root/.profile

# === Python 패키지 관리 도구 설치 ===
RUN curl -sSf https://rye.astral.sh/get | RYE_HOME="/root/.rye" RYE_VERSION="latest" RYE_INSTALL_OPTION="--yes" bash && \
    echo 'source /root/.rye/env' >> /root/.profile

# === memlimit 설치 ===
# NOTE: RunPod은 OOM(Out of Memory)에서도 프로세스를 종료하지 않음.
#       그래서 OOM을 유발하는 프로세스가 생기면 무한히 대기해야함. (=돈낭비)
#       따라서 프로세스를 종료할 수 있도록 미리 장치를 마련해야하는데, memlimit으로 해결하려고 함.
# REF: https://github.com/shadyfennec/memlimit
RUN source /root/.profile && \
    cargo install memlimit

# === RunPod을 위한 jupyterlab 설정 (전역 설치) ===
RUN source /root/.rye/env && \
    rye install jupyterlab && \
    rye install magic-wormhole && \
    rye install invoke

# === NGINX 프록시 설정 ===
RUN wget -O init-deb.sh https://www.linode.com/docs/assets/660-init-deb.sh && \
    mv init-deb.sh /etc/init.d/nginx && \
    chmod +x /etc/init.d/nginx && \
    /usr/sbin/update-rc.d -f nginx defaults

# === 프록시 설정 파일 복사 ===
COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy readme.html /usr/share/nginx/html/readme.html
COPY README.md /usr/share/nginx/html/README.md

# === 시작 스크립트 설정 ===
COPY --from=scripts post_start.sh /
COPY --from=scripts start.sh /
RUN chmod +x /start.sh

# === 컨테이너 포트 노출 ===
# TCP Ports
EXPOSE 22 8000 8080
# HTTP Ports
EXPOSE 80 443

# === 기본 명령어 설정 ===
CMD ["/start.sh"]