# RunPod용 베이스 이미지 - 필요에 따라 버전 변경 (작성 시점 기준 0.2)
# 참조: https://github.com/runpod/containers/tree/main/official-templates/base - 베이스 Dockerfile
# 참조: https://github.com/runpod/containers/tree/main/container-template - 의존성 스크립트 (이것들 있어야 컨테이너가 runpod에서 제대로 돌아감) 

# 기본 베이스 이미지 설정 (외부에서 전달 가능)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Bash를 기본 쉘로 설정하고 파이프 오류를 방지
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 환경 변수 설정
ENV SHELL=/bin/bash
ENV PYTHONUNBUFFERED=True
ENV DEBIAN_FRONTEND=noninteractive

# 베이스 릴리즈 버전 설정 (외부에서 전달 가능)
ARG BASE_RELEASE_VERSION
ENV BASE_RELEASE_VERSION=${BASE_RELEASE_VERSION}

# Hugging Face 캐시 디렉터리 설정 (모델 다운로드 속도 최적화)
ENV HF_HOME="/runpod-volume/.cache/huggingface/"
ENV HF_DATASETS_CACHE="/runpod-volume/.cache/huggingface/datasets/"
ENV DEFAULT_HF_METRICS_CACHE="/runpod-volume/.cache/huggingface/metrics/"
ENV DEFAULT_HF_MODULES_CACHE="/runpod-volume/.cache/huggingface/modules/"
ENV HUGGINGFACE_HUB_CACHE="/runpod-volume/.cache/huggingface/hub/"
ENV HUGGINGFACE_ASSETS_CACHE="/runpod-volume/.cache/huggingface/assets/"
# 모델 다운로드 최적화 활성화
ENV HF_HUB_ENABLE_HF_TRANSFER="1"  

# Python 패키지 캐시 디렉터리 설정 (공유 및 속도 향상)
ENV VIRTUALENV_OVERRIDE_APP_DATA="/runpod-volume/.cache/virtualenv/"
ENV PIP_CACHE_DIR="/runpod-volume/.cache/pip/"
ENV UV_CACHE_DIR="/runpod-volume/.cache/uv/"

# 기본 Python 버전 설정
ENV PYTHON_VERSION="3.10"

# 작업 디렉터리 설정
WORKDIR /

# 필수 패키지 설치 및 시스템 업데이트

# NOTE: APT 미러 서버 변경 시, 프로토콜(http/https)과 경로 끝에 파일 구분자('/')가 올바르게 설정되었는지 반드시 확인해야 합니다.
# 잘못된 경로 설정은 apt-get이 정상적으로 동작하지 않게 만들 수 있습니다.
# NOTE: 'sed'는 문자열을 변환하는 도구로, APT 소스 리스트 파일을 수정하는 데 사용됩니다.
# NOTE: 국가별로 적합한 레지스트리 정보를 찾으려면 http://mirrors.ubuntu.com/ 를 참고하세요.
# NOTE: 경로가 http://archive.ubuntu.com/ubuntu/와 같이 '/'로 끝나면 제대로 동작하지 않으므로, 주의해서 변경해야 합니다.
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|' /etc/apt/sources.list

RUN apt-get update
RUN apt-get upgrade --yes
# 기본 유틸리티 설치
RUN apt install --yes --no-install-recommends \
    bash ca-certificates curl file git inotify-tools jq \
    libgl1 lsof vim nano nginx \
    # SSH 및 시스템 도구
    openssh-server procps rsync sudo software-properties-common\
    unzip wget zip
# 개발 및 빌드 도구 설치
RUN apt install --yes --no-install-recommends \
    build-essential make cmake gfortran libblas-dev liblapack-dev
# 이미지 및 비디오 처리 관련 라이브러리 설치
RUN apt install --yes --no-install-recommends \
    ffmpeg libavcodec-dev libavfilter-dev libavformat-dev libavutil-dev \
    libjpeg-dev libpng-dev libpostproc-dev libswresample-dev libswscale-dev \
    libtiff-dev libv4l-dev libx264-dev libxext6 libxrender-dev libxvidcore-dev
# 머신러닝 및 기타 필수 라이브러리 설치
RUN apt install --yes --no-install-recommends \
    libatlas-base-dev libffi-dev libhdf5-serial-dev libsm6 libssl-dev
# 파일 시스템 및 압축 관련 유틸리티
RUN apt install --yes --no-install-recommends \
    cifs-utils nfs-common zstd
# Python 관련 PPA 추가 및 다중 버전 지원
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install --yes --no-install-recommends \
    python3.7-dev python3.7-venv python3.7-distutils \
    python3.8-dev python3.8-venv python3.8-distutils \
    python3.9-dev python3.9-venv python3.9-distutils \
    python3.10-dev python3.10-venv python3.10-distutils \
    python3.11-dev python3.11-venv python3.11-distutils
# 시스템 정리 (불필요한 파일 제거하여 이미지 최적화)
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* 

# 로케일 설정
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# NOTE: 나(devcomfort)는 rye만 쓰지만, 이 컨테이너의 사용자를 위해 일반적인 설정을 유지하기로 함. 즉, python, pip, venv, uv 셋업을 유지함.
# Python 패키지 관리 도구 (pip) 설치
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3.8 get-pip.py && python3.9 get-pip.py && \
    python3.10 get-pip.py && python3.11 get-pip.py

# 모든 Python 버전에 대해 최신 pip 설치
RUN python3.8 -m pip install --upgrade pip && \
    python3.9 -m pip install --upgrade pip && \
    python3.10 -m pip install --upgrade pip && \
    python3.11 -m pip install --upgrade pip

# virtualenv 설치
RUN python3.8 -m pip install virtualenv && \
    python3.9 -m pip install virtualenv && \
    python3.10 -m pip install virtualenv && \
    python3.11 -m pip install virtualenv

# pip 대체 도구 uv 설치
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# TODO: 비루트(Non-root) 사용자 생성 여부를 결정해야 함.  
# 특정 사용자명을 고정하는 것이 적절한지 고민이 필요하여 현재 사용자 생성 코드를 주석 처리함.  
# 추후 필요할 경우, 사용자명을 외부 인자로 받아 동적으로 설정할 계획.  

# RUN useradd -m {username} \
#     echo "{username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# USER {username}

# filebrowser 설치
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# pyenv 설치 (from webinstall.dev)
RUN curl -sS https://webi.sh/pyenv | sh; \
    source ~/.config/envman/PATH.env

# GitHub CLI 설치
RUN curl -sS https://webi.sh/gh | bash
ENV PATH="${PATH}:~/.local/bin/gh"

# Rye (Python 패키지 관리 도구) 설치
RUN curl -sSf https://rye.astral.sh/get | RYE_VERSION="latest" RYE_INSTALL_OPTION="--yes" bash

# TODO: 이전에 USER 절을 사용하여 다른 계정으로 전환한 경우에만  
# 루트 사용자로 복귀하는 로직을 적용해야 함.  

# 루트 사용자로 전환  
# USER root

# NGINX 설정 및 관련 파일 복사
COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy readme.html /usr/share/nginx/html/readme.html
COPY README.md /usr/share/nginx/html/README.md

# 실행 스크립트 복사 및 실행 권한 설정
COPY --from=scripts start.sh /
COPY --from=scripts post_start.sh /
RUN chmod +x /start.sh && chmod +x /post_start.sh

# 환영 메시지 설정
COPY --from=logo runpod.txt /etc/runpod.txt
RUN echo 'cat /etc/runpod.txt' >> /root/.bashrc
RUN echo 'echo -e "\nFor detailed documentation and guides, visit:\n\033[1;34mhttps://docs.runpod.io/\033[0m and \033[1;34mhttps://blog.runpod.io/\033[0m\n\n"' >> /root/.bashrc

# 컨테이너 시작 시 실행할 기본 명령어 설정
CMD ["/start.sh"]