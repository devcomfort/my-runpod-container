# 🔧 도구 관리 매트릭스

## 🎯 핵심 문제점 인식

> **개발자가 로컬에서 관리해야 하는 도구 vs 컨테이너 내부 도구를 혼재하여 관리하고 있었습니다.**

## 📋 올바른 도구 분류

### 💻 개발자 로컬 환경 도구 (개발자가 직접 관리)

**개발자가 실제로 업데이트하고 관리해야 하는 도구들**

| 도구 | 현재 관리 방식 | 올바른 관리 방식 | 업데이트 주체 |
|------|----------------|------------------|---------------|
| **Docker Engine** | ❌ 관리 안함 | ✅ 시스템 패키지 매니저 | 개발자 |
| **Docker Buildx** | ❌ `.versions.env` | ✅ 개발자 직접 설치/업데이트 | 개발자 |
| **Git** | ❌ 관리 안함 | ✅ 시스템 패키지 매니저 | 개발자 |
| **VS Code Desktop** | ❌ 관리 안함 | ✅ 개발자 직접 업데이트 | 개발자 |
| **Node.js/npm** | ❌ 관리 안함 | ✅ nvm 또는 시스템 패키지 | 개발자 |

#### 🚀 개발자 로컬 도구 관리 가이드

```bash
# Docker Engine 업데이트
sudo apt update && sudo apt upgrade docker-ce

# Docker Buildx 업데이트 
docker buildx install  # 또는 수동 설치

# Git 업데이트
sudo apt update && sudo apt upgrade git

# VS Code 업데이트
# GUI를 통해 자동 업데이트 또는 다운로드
```

### 🐳 컨테이너 내부 도구 (.versions.env로 관리)

**빌드 시 고정 버전으로 설치되는 도구들**

| 도구 | 위치 | 관리 방식 | 업데이트 주체 |
|------|------|-----------|---------------|
| **Go** | 컨테이너 내부 | ✅ `.versions.env` | 개발팀 |
| **Rust** | 컨테이너 내부 | ✅ `.versions.env` | 개발팀 |
| **GitHub CLI** | 컨테이너 내부 | ✅ `.versions.env` | 개발팀 |
| **VS Code Server** | 컨테이너 내부 | ✅ `.versions.env` | 개발팀 |
| **TinyGo** | 컨테이너 내부 | ✅ `.versions.env` | 개발팀 |
| **Slurm Client** | 컨테이너 내부 | ✅ 옵션 설정 | 개발팀 |

### ☁️ CI/CD 환경 도구 (CI/CD 설정으로 관리)

**GitHub Actions 등에서 자동 관리되는 도구들**

| 도구 | 관리 방식 | 설정 위치 |
|------|-----------|-----------|
| **GitHub Actions Runner** | GitHub 자동 관리 | N/A |
| **Docker in CI** | `docker/setup-buildx-action@v3` | `.github/workflows/` |
| **Node.js in CI** | `actions/setup-node@v4` | `.github/workflows/` |

## 🔄 수정된 관리 구조

### 1. 📁 파일 재분류

#### `.versions.env` (컨테이너 도구만)
```bash
# 컨테이너 내부 도구들만 관리
GO_VERSION=1.23.4
TINYGO_VERSION=0.38.0
GH_VERSION=2.76.1
VS_CODE_VERSION=latest
```

#### `dev-requirements.md` (새로 생성 예정)
```markdown
# 개발자 로컬 환경 요구사항
- Docker Engine >= 24.0
- Docker Buildx >= 0.26.0
- Git >= 2.40
- VS Code >= 1.85 (선택사항)
```

#### `.github/workflows/build-and-push.yml` (CI/CD 도구)
```yaml
- uses: docker/setup-buildx-action@v3
  with:
    version: v0.26.1  # CI 전용 고정 버전
```

### 2. 🎯 개발자 워크플로우 수정

#### 기존 (잘못된 방식)
```bash
# 개발자가 컨테이너 도구 버전을 관리
python3 scripts/update-versions.py
```

#### 수정된 방식
```bash
# 1. 로컬 도구 관리 (개발자 직접)
sudo apt upgrade docker-ce docker-buildx-plugin

# 2. 컨테이너 도구 관리 (프로젝트 팀)
python3 scripts/update-container-versions.py

# 3. 로컬 환경 검증
./scripts/check-dev-requirements.sh
```

## 🚨 현재 수정이 필요한 사항

### ❌ 문제점
1. `BUILDX_VERSION`이 `.versions.env`에 있음 (잘못된 위치)
2. 개발자 로컬 도구 관리 가이드 부족
3. CI/CD와 로컬 환경의 요구사항 혼재

### ✅ 해결 방안
1. `.versions.env`에서 `BUILDX_VERSION` 제거
2. `dev-requirements.md` 생성 
3. 개발자용 환경 체크 스크립트 생성
4. CI/CD 전용 버전 설정 분리

## 🎯 다음 단계

1. **`.versions.env` 정리**: 컨테이너 도구만 남기기
2. **개발자 가이드 생성**: 로컬 도구 관리 방법
3. **환경 체크 스크립트**: 개발자 요구사항 검증
4. **CI/CD 분리**: GitHub Actions 전용 설정 