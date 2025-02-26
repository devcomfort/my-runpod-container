# Personal RunPod Environment

이 프로젝트는 RunPod를 위한 개인 환경을 구성하기 위한 Docker 이미지를 제공합니다. 기본 RunPod 컨테이너에 `gh`, `htop`, `rye` 등 유용한 도구가 추가되어 있습니다.

## 주요 특징

- 다양한 CUDA 버전 지원 (CPU 전용 버전도 제공)
- 편리한 개발 도구 포함 (`gh`, `htop`, `rye`)
- 최적화된 APT 미러 서버 설정

## Makefile을 이용한 빌드 및 배포

이 프로젝트는 다양한 버전의 이미지를 쉽게 관리할 수 있는 Makefile을 제공합니다:

```bash
# 주요 명령어
make build      # 모든 버전 동시 빌드
make push       # 모든 버전 동시 빌드 및 Docker Hub에 푸시
make all-seq    # 모든 버전 순차적으로 빌드 후 푸시

# 특정 타겟 작업
make 11-8-0     # CUDA 11.8.0 버전만 빌드
make push-11-8-0  # CUDA 11.8.0 버전만 푸시

# 유지보수 명령어
make clean      # 도커 리소스 정리
make help       # 도움말 표시
```

지원되는 빌드 타겟: `cpu`, `11-1-1`, `11-8-0`, `12-1-0`, `12-2-0`, `12-4-1`, `12-5-1`, `12-6-2`

## RunPod Template 설정

RunPod에서 이 이미지를 사용하려면 다음과 같이 Template을 설정하세요:

1. **Container Image**: 
   - `docker.io/devcomfort/personal-runpod-environment:0.2-cuda11.8.0` 
   - (또는 필요한 CUDA 버전에 맞게 선택)

2. **Expose HTTP Ports (Max 10)**:
   - `80, 443`

3. **Expose TCP Ports**:
   - `22, 8080, 8000`

## 중요 참고사항

**RunPod에서는 Pod 설정 시 할당된 공개 IP를 통해서만 SSH 접속이 가능합니다.** 공개 IP가 할당되지 않은 환경에서는 SSH 접속이 불가능하므로 Template 구성 시 적절한 네트워크 설정이 필요합니다.

- APT 미러 서버 주소를 변경할 경우, `archive.ubuntu.com`과 `security.ubuntu.com` 모두 일관되게 변경해야 합니다. 미러 서버마다 패키지 정보가 다르기 때문에 불일치 시 보안 검사에서 오류가 발생할 수 있습니다.
- 현재 APT 미러 주소는 카카오 서버를 사용하도록 설정되어 있어 `htop` 등의 패키지 설치 문제를 해결했습니다.