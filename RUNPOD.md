# RunPod Platform Guide

**RunPod 플랫폼에서 이 컨테이너를 사용하기 위한 상세 가이드**

RunPod은 GPU 클라우드 컴퓨팅 플랫폼으로, 이 문서는 RunPod에서 컨테이너를 효과적으로 사용하기 위한 플랫폼별 설정과 환경변수에 대해 설명합니다.

## 🔧 RunPod 환경변수

### 자동 주입되는 환경변수

RunPod 플랫폼은 컨테이너 실행 시 다음 환경변수들을 **자동으로 주입**합니다:

| Variable | Purpose | 출처 |
|----------|---------|------|
| `RUNPOD_POD_ID` | Pod의 고유 식별자 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_API_KEY` | 이 Pod 전용 RunPod API 키 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_POD_HOSTNAME` | Pod가 실행 중인 서버의 호스트명 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_GPU_COUNT` | Pod에 할당된 총 GPU 수 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_CPU_COUNT` | Pod에 할당된 총 CPU 수 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_PUBLIC_IP` | Pod의 공개 IP 주소 (가능한 경우) | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_TCP_PORT_22` | SSH(포트 22)에 매핑된 공개 포트 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_ALLOW_IP` | Pod 접근 허용 IP 주소 목록 (쉼표 구분) | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_DC_ID` | Pod가 위치한 데이터센터 식별자 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `RUNPOD_VOLUME_ID` | Pod에 연결된 네트워크 볼륨 ID | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `CUDA_VERSION` | Pod 환경에 설치된 CUDA 버전 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `PYTORCH_VERSION` | Pod 환경에 설치된 PyTorch 버전 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `PUBLIC_KEY` | SSH 접근 권한이 있는 SSH 공개키들 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |
| `PWD` | Pod 내부의 현재 작업 디렉토리 | [공식 문서](https://docs.runpod.io/pods/references/environment-variables) |

### 사용자 설정 환경변수

| Variable | Purpose | 설정 방법 |
|----------|---------|----------|
| `SSH_PUBLIC_KEY` | 특정 Pod용 SSH 공개키 오버라이드 | 템플릿 환경변수 ([공식 문서](https://docs.runpod.io/pods/configuration/use-ssh)) |
| `RUNPOD_SECRET_*` | RunPod Secrets 참조 | 템플릿에서 `{{ RUNPOD_SECRET_키이름 }}` 형식 ([공식 문서](https://docs.runpod.io/pods/templates/secrets)) |

### SSH 키 관리

RunPod은 **세 가지 방식**으로 SSH 키를 관리합니다:

#### 1. RunPod 계정 설정 (권장)
```bash
# 1. 로컬에서 SSH 키 생성 (없는 경우)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. 공개키 복사
cat ~/.ssh/id_ed25519.pub

# 3. RunPod Dashboard → Account Settings → SSH Keys에 추가
```

**결과:** 계정에 등록된 모든 SSH 키가 `PUBLIC_KEY` 환경변수에 자동 주입됩니다.

#### 2. 템플릿 환경변수 (Pod별 설정)
```bash
# RunPod 템플릿에서 설정
SSH_PUBLIC_KEY=ssh-rsa AAAAB3NzaC1yc2E...
```

**동작:** `SSH_PUBLIC_KEY`가 설정되면 계정 설정의 키들을 오버라이드합니다.

#### 3. 컨테이너 내 수동 설정
```bash
# 컨테이너 내에서 직접 설정 (이 컨테이너에서 지원)
PUBLIC_KEY=ssh-rsa AAAAB3NzaC1yc2E...
```

**출처:** [RunPod SSH 공식 문서](https://docs.runpod.io/pods/configuration/use-ssh)

### 타임존 설정

**RunPod은 `TZ` 환경변수를 자동으로 주입하지 않습니다.** 타임존은 다음과 같이 관리됩니다:

```bash
# 1. 컨테이너 기본값: Asia/Seoul (Dockerfile에서 설정)
ENV TZ=Asia/Seoul

# 2. RunPod 템플릿에서 오버라이드 가능
TZ=UTC
TZ=America/New_York
TZ=Europe/London

# 3. 컨테이너 내에서 확인
echo $TZ
date
```

**동작 방식:**
- RunPod 플랫폼은 `TZ` 환경변수를 주입하지 않음
- 컨테이너의 기본 설정(Asia/Seoul) 유지
- 사용자가 템플릿에서 `TZ` 환경변수 설정 시 오버라이드됨

**출처:** [RunPod 환경변수 공식 문서](https://docs.runpod.io/pods/references/environment-variables) (TZ 변수 없음 확인)

## 🚀 RunPod 템플릿 설정

### 기본 환경변수
```bash
# 필수 서비스 설정
JUPYTER_PASSWORD=your-secure-password-123
ENABLE_FILEBROWSER=1
ENABLE_HTTP_SERVER=0
```

### 고급 설정
```bash
# GPU 선택적 사용
NVIDIA_VISIBLE_DEVICES=0,1  # GPU 0,1번만 사용
NVIDIA_VISIBLE_DEVICES=all  # 모든 GPU 사용

# 커스텀 타임존
TZ=UTC

# 추가 SSH 키 (계정 설정 외)
PUBLIC_KEY=ssh-rsa AAAAB3NzaC1yc2E...

# 서비스 토글
ENABLE_FILEBROWSER=0  # 파일브라우저 비활성화
ENABLE_HTTP_SERVER=1  # HTTP 서버 활성화
```

## 🌐 포트 매핑

RunPod은 컨테이너의 **모든 EXPOSE된 포트**를 자동으로 외부에 노출합니다. ([공식 문서](https://docs.runpod.io/pods/configuration/expose-ports))

### RunPod 포트 매핑 동작
- **자동 감지**: Dockerfile의 `EXPOSE` 지시어로 선언된 포트들을 자동 매핑
- **동적 할당**: 각 포트마다 고유한 외부 포트 번호 할당
- **환경변수 제공**: `RUNPOD_TCP_PORT_22` 등으로 매핑된 외부 포트 번호 제공

### 이 컨테이너의 노출 포트
```dockerfile
# Dockerfile에서 EXPOSE된 포트들
EXPOSE 22        # SSH (RUNPOD_TCP_PORT_22로 외부 포트 확인 가능)
EXPOSE 8888      # Jupyter Lab
EXPOSE 4041      # Filebrowser  
EXPOSE 8089      # HTTP Server
EXPOSE 8081      # Code Server
EXPOSE 8001      # VS Code Server
EXPOSE 5001 6001 7001 9001  # 범용 개발 포트
EXPOSE 7861 9091 3001 7270  # 특수 목적 포트
```

### 외부 포트 확인 방법
```bash
# SSH 포트 확인
echo $RUNPOD_TCP_PORT_22

# 모든 TCP 포트 매핑 확인
env | grep RUNPOD_TCP_PORT

# RunPod 웹 인터페이스에서도 확인 가능
```

**출처:** [RunPod 포트 노출 공식 문서](https://docs.runpod.io/pods/configuration/expose-ports)

## 🔍 환경변수 확인 방법

컨테이너 내에서 RunPod 환경변수 확인:

```bash
# RunPod 관련 환경변수 모두 보기
env | grep RUNPOD

# 모든 환경변수 보기
env | sort

# 특정 패턴으로 환경변수 검색
env | grep -E "(RUNPOD|NVIDIA|CUDA)"
```

## 🛠️ 트러블슈팅

### SSH 접속 문제
```bash
# 1. SSH 키가 제대로 설정되었는지 확인
cat ~/.ssh/authorized_keys

# 2. SSH 서비스 상태 확인
service ssh status

# 3. SSH 키 권한 확인
ls -la ~/.ssh/
```

### 서비스 시작 문제
```bash
# 1. 환경변수 확인
env | grep ENABLE

# 2. 서비스 로그 확인
tail -f /jupyter.log
tail -f /http_server.log

# 3. 프로세스 확인
ps aux | grep jupyter
ps aux | grep filebrowser
```

### 포트 접근 문제
```bash
# 1. nginx 상태 확인
service nginx status

# 2. 포트 리스닝 확인
netstat -tlnp | grep :8888
netstat -tlnp | grep :4040

# 3. nginx 설정 확인
nginx -t
```

## 📚 참고 자료

### RunPod 공식 문서
- [환경변수 레퍼런스](https://docs.runpod.io/pods/references/environment-variables) - 자동 주입되는 환경변수 전체 목록
- [SSH 설정](https://docs.runpod.io/pods/configuration/use-ssh) - SSH 키 관리 방법
- [포트 노출](https://docs.runpod.io/pods/configuration/expose-ports) - 포트 매핑 동작 방식
- [템플릿 시크릿](https://docs.runpod.io/pods/templates/secrets) - 민감한 정보 관리
- [볼륨 설정](https://docs.runpod.io/pods/storage/overview) - 스토리지 관리

### 커뮤니티 자료
- [SSH 설정 가이드](https://cold-soup.tistory.com/337) - RunPod SSH 키 설정 실습
- [CI/CD 가이드](https://github-wiki-see.page/m/LxNx-Hn/chatbot-with-kt-dgucenter/wiki/CI-CD-가이드문서) - RunPod 레지스트리 인증 및 배포
- [RunPod 서버리스 가이드](https://visionhong.github.io/tools/runpod-serverless/) - 서버리스 엔드포인트 설정

## 💡 Best Practices

### 1. 환경변수 관리
- 민감한 정보는 RunPod 템플릿의 환경변수로 설정
- SSH 키는 계정 설정 사용 권장
- 개발용 설정과 프로덕션 설정 분리

### 2. 서비스 설정
- 불필요한 서비스는 비활성화하여 리소스 절약
- 포트 충돌 방지를 위한 사전 계획
- 로그 모니터링으로 서비스 상태 확인

### 3. 보안
- 강력한 Jupyter 패스워드 사용
- SSH 키 정기적 갱신
- 불필요한 포트 노출 최소화

---

**Note:** 이 문서의 정보는 커뮤니티 경험과 비공식 출처를 기반으로 작성되었습니다. RunPod 플랫폼의 업데이트에 따라 동작이 변경될 수 있으므로, 최신 정보는 공식 채널을 통해 확인하시기 바랍니다.
