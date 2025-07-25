# 🔧 개발 및 빌드 환경 분리 가이드

## 📋 실행 컨텍스트 분리

### 🎯 핵심 원칙

> **Docker 빌드는 불변성을 보장해야 하며, 개발 환경 설정과 명확히 분리되어야 합니다.**

## 🔧 Development Time (개발 시점)

**개발자가 로컬 환경에서 수행하는 작업들**

### 📁 관련 파일들

| 파일 | 역할 | 실행 주체 |
|------|------|-----------|
| `.versions.env` | 중앙 버전 관리 | 개발자 |
| `scripts/update-versions.py` | 버전 동기화 도구 | 개발자 |
| `scripts/simple-version-test.sh` | 로컬 테스트 | 개발자 |
| `scripts/test-version-integration.sh` | 통합 테스트 | 개발자 |
| `setup_multi_architecture_build.sh` | 빌드 환경 설정 | 개발자 |

### 🚀 개발자 워크플로우

```bash
# 1. 버전 확인 및 업데이트
python3 scripts/update-versions.py --check-latest
python3 scripts/update-versions.py  # 실제 동기화

# 2. 로컬 테스트
./scripts/simple-version-test.sh

# 3. 빌드 환경 설정 (최초 1회)
sudo ./setup_multi_architecture_build.sh

# 4. 로컬 빌드 테스트
docker buildx bake --print cpu  # 설정 확인
```

### ⚠️ 개발 시점 주의사항

- `.versions.env` 수정 후 반드시 동기화 실행
- 로컬 테스트로 일관성 확인
- 빌드 전 버전 충돌 없는지 검증

## 🏗️ Build Time (빌드 시점)

**Docker가 이미지를 빌드하는 과정**

### 📁 관련 파일들

| 파일 | 역할 | 실행 주체 |
|------|------|-----------|
| `Dockerfile` | 이미지 정의 | Docker Engine |
| `docker-bake.hcl` | 빌드 설정 | Docker Buildx |
| `ARG` 변수들 | 고정 버전 전달 | Docker Build |
| `RUN` 명령들 | 도구 설치 | Docker Build |

### 🔒 빌드 시점 특징

```dockerfile
# ✅ 올바른 빌드 시점 패턴
ARG GO_VERSION="1.23.4"  # 고정 버전
RUN curl -sSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz

# ❌ 잘못된 빌드 시점 패턴  
RUN python3 scripts/update-versions.py  # 동적 업데이트 불가!
```

### 🎯 빌드 시점 원칙

- **고정성**: 모든 버전은 빌드 시 고정
- **재현성**: 언제든 동일한 이미지 생성 가능
- **격리성**: 외부 환경 변화에 독립적

## 🚀 Runtime (런타임 시점)

**컨테이너가 실행되는 과정**

### 📁 관련 파일들

| 파일 | 역할 | 실행 시점 |
|------|------|-----------|
| `scripts/start.sh` | 컨테이너 진입점 | 컨테이너 시작 |
| `src/serve-remote.py` | VS Code 서버 | 런타임 |
| `scripts/post_start.sh` | 시작 후 설정 | 런타임 |

### 🔄 런타임 특징

- **고정 도구**: 빌드 시 설치된 도구 사용
- **환경 설정**: 런타임 환경 변수 적용
- **서비스 시작**: 웹 서버, SSH 등 시작

## 📋 올바른 분리 예시

### ✅ 개발 환경에서

```bash
# 개발자가 새 버전 발견 시
echo 'GH_VERSION=2.77.0' >> .versions.env
python3 scripts/update-versions.py  # 모든 파일 동기화
./scripts/simple-version-test.sh     # 테스트
```

### ✅ CI/CD에서

```yaml
# GitHub Actions
- name: Build and push
  uses: docker/bake-action@v4
  with:
    files: ./docker-bake.hcl  # 빌드 설정만 사용
    targets: cpu
    push: true
```

### ❌ 피해야 할 패턴

```dockerfile
# Dockerfile에서 이런 것들 금지:
COPY scripts/update-versions.py /tmp/
RUN python3 /tmp/update-versions.py  # 빌드 중 동적 업데이트 금지!
```

## 🎯 권장 사항

### 🔧 개발자용

1. **버전 업데이트 전 체크리스트**
   - [ ] `.versions.env` 백업
   - [ ] `update-versions.py` 실행
   - [ ] `simple-version-test.sh` 통과
   - [ ] 로컬 빌드 테스트

2. **빌드 전 체크리스트**
   - [ ] 모든 테스트 통과
   - [ ] `.versions.env`와 다른 파일 동기화 확인
   - [ ] `docker-bake.hcl` 문법 검증

### 🏗️ CI/CD용

1. **빌드 파이프라인**
   - 고정된 빌드 설정만 사용
   - 환경 변수로 동적 요소 최소화
   - 캐시 전략으로 속도 최적화

2. **테스트 자동화**
   - 빌드된 이미지 기능 검증
   - 다중 아키텍처 호환성 확인

## 🚨 문제 해결

### 버전 불일치 발생 시

```bash
# 1. 현재 상태 확인
./scripts/simple-version-test.sh

# 2. 강제 동기화
python3 scripts/update-versions.py

# 3. 재검증
./scripts/simple-version-test.sh
```

### 빌드 실패 시

```bash
# 1. 빌드 설정 검증
docker buildx bake --print cpu

# 2. 문법 검사
docker buildx bake --help

# 3. 개별 타겟 테스트
docker buildx bake cpu --dry-run
``` 