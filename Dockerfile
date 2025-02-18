# RunPod용 베이스 이미지 - 필요에 따라 버전 변경해주세요 (작성 시점 기준 0.2)
# 베이스 이미지는 RunPod에서 제공하는 CUDA 11.8.0이 포함된 이미지를 사용합니다.
FROM runpod/base:0.6.3-cuda11.8.0

# NOTE: htop을 설치할 수 없어서 미러 주소를 변경합니다.
# Kakao 미러를 사용하여 패키지 다운로드 속도를 향상시킵니다.
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.kakao.com/ubuntu/|g' /etc/apt/sources.list && \
    # 패키지 목록 업데이트
    apt-get update -y && \  
    # 시스템 패키지 업그레이드
    apt-get upgrade -y    

# htop 설치: 시스템 모니터링 도구
RUN apt-get install htop -y

# GitHub CLI 설치
RUN curl -sS https://webi.sh/gh | bash
# 설치 후 PATH에 GitHub CLI를 추가
ENV PATH="${PATH}:~/.local/bin/gh"

# Rye 설치: Python 패키지 관리 도구
RUN curl -sSf https://rye.astral.sh/get | RYE_VERSION="latest" RYE_INSTALL_OPTION="--yes" bash

# Docker 설치: Docker를 설치하기 위한 스크립트를 다운로드하고 실행합니다.
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN bash get-docker.sh

# Docker 데몬을 백그라운드에서 시작합니다.
RUN dockerd &

# NGINX Proxy 설정
# NGINX 설정 파일 및 기본 HTML 페이지를 복사합니다.
COPY ./proxy/nginx.conf /etc/nginx/nginx.conf
COPY ./proxy/readme.html /usr/share/nginx/html/readme.html

# 시작 스크립트 복사
# 컨테이너 시작 시 실행할 스크립트를 복사하고 실행 권한을 부여합니다.
COPY ./scripts/start.sh /
COPY ./scripts/post_start.sh /
RUN chmod +x /start.sh && \
    chmod +x /post_start.sh

# 환영 메시지 설정
# RunPod 관련 정보를 포함하는 텍스트 파일을 복사합니다.
COPY ./logo/runpod.txt /etc/runpod.txt
# 사용자가 로그인할 때마다 환영 메시지를 출력하도록 설정합니다.
RUN echo 'cat /etc/runpod.txt' >> /root/.bashrc
RUN echo 'echo -e "\nFor detailed documentation and guides, please visit:\n\033[1;34mhttps://docs.runpod.io/\033[0m and \033[1;34mhttps://blog.runpod.io/\033[0m\n\n"' >> /root/.bashrc

# 컨테이너의 기본 명령어를 설정합니다. 
# /start.sh 스크립트를 실행하여 필요한 서비스들을 시작합니다.
CMD [ "/start.sh" ]
