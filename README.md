# Personal RunPod Environment

이 프로젝트는 RunPod를 위한 개인 환경을 구성하기 위한 Docker 이미지를 제공합니다. 기본 RunPod 컨테이너에 `gh`, `htop`, `rye` 등 유용한 도구가 추가되어 있습니다.

## 주요 특징

- 다양한 CUDA 버전 지원 (CPU 전용 버전도 제공)
- 편리한 개발 도구 포함 (`gh`, `htop`, `rye`)
- 최적화된 APT 미러 서버 설정
- 멀티 아키텍처 빌드 지원 (CPU: linux/amd64, linux/arm64)

## 빌드 및 배포 가이드

### ⚠️ 중요 시스템 요구사항 ⚠️

**빌드에는 최소 400GB 이상의 유휴 스토리지 공간이 필요합니다.**

도커 이미지 빌드 과정에서 레이어와 캐시가 많은 공간을 차지하기 때문에, 특히 멀티 아키텍처 빌드와 여러 CUDA 버전을 동시에 빌드할 경우 최소 400GB 이상의 여유 공간이 필요합니다. 개발 환경에서는 1TB 이상의 스토리지 공간을 권장합니다.

### 빌드 준비

1. **멀티 아키텍처 빌드 환경 설정**

```bash
# 스크립트에 실행 권한 추가
chmod +x setup_multi_architecture_build.sh

# 스크립트 실행 (sudo 권한 필요)
sudo ./setup_multi_architecture_build.sh
```

2. **Docker Hub 로그인**

```bash
docker login
```

### Makefile 빌드 명령어

```bash
# 기본 명령어
make build      # 모든 버전 동시 빌드
make push       # 모든 버전 빌드 및 푸시
make all-seq    # 순차적 빌드 및 푸시 (시스템 부하 감소)

# 특정 타겟만 작업
make 11-8-0     # 특정 버전 빌드
make push-11-8-0  # 특정 버전 푸시

# 유지보수
make clean      # 도커 리소스 정리
make help       # 도움말
```

### 환경 변수 및 설정

Makefile 및 docker-bake.hcl은 다음 환경 변수를 사용합니다:

```bash
# 환경 변수 설정 예시
RELEASE=0.3 DOCKER_HUB_USERNAME=사용자명 make build

# 또는 .env 파일 생성
echo "RELEASE=0.3" > .env
echo "DOCKER_HUB_USERNAME=사용자명" >> .env
```

### 지원 빌드 타겟

| 타겟 | 설명 | 지원 아키텍처 |
|------|------|--------------|
| `cpu` | CPU 전용 버전 | linux/amd64, linux/arm64 |
| `11-1-1` | CUDA 11.1.1 | linux/amd64 |
| `11-8-0` | CUDA 11.8.0 | linux/amd64 |
| `12-1-0` | CUDA 12.1.0 | linux/amd64 |
| `12-2-0` | CUDA 12.2.0 | linux/amd64 |
| `12-4-1` | CUDA 12.4.1 | linux/amd64 |
| `12-5-1` | CUDA 12.5.1 | linux/amd64 |
| `12-6-2` | CUDA 12.6.2 | linux/amd64 |

## Dockerfile 주요 구성

`Dockerfile`은 다양한 기본 이미지(BASE_IMAGE)를 지원하도록 설계되었으며 다음 요소들을 포함합니다:

- 기본 시스템 패키지 (build-essential, cmake, git 등)
- 이미지/비디오 처리 라이브러리 (ffmpeg 등)
- 개발 도구 (gh, golang, rust, rye)
- 유틸리티 (ollama, memlimit, code-server)

## RunPod 사용 가이드

### Template 설정

1. **Container Image**: 
   - `docker.io/devcomfort/personal-runpod-environment:0.2-cuda11.8.0`
   - (필요한 CUDA 버전 선택)

2. **Expose HTTP Ports**: `80, 443`

3. **Expose TCP Ports**: `22, 8080, 8000`

### 주의사항

- **SSH 접속**: RunPod에서는 공개 IP가 할당된 경우에만 SSH 접속이 가능합니다.
- **APT 미러 서버**: `archive.ubuntu.com`과 `security.ubuntu.com` 모두 일관되게 설정해야 합니다. 현재는 카카오 미러 서버를 사용합니다.

## 참고 자료

멀티아키텍처 빌드 관련: [Multi-architecture Docker Images 빌드 환경 구성하기](https://medium.com/@dudwls96/multi-architecture-docker-images-%EB%B9%8C%EB%93%9C-%ED%99%98%EA%B2%BD-%EA%B5%AC%EC%84%B1%ED%95%98%EA%B8%B0-421ca3ae380d)
