# 💻 개발자 로컬 환경 요구사항

## 🎯 개발자가 직접 관리해야 하는 로컬 도구들

> **중요**: 이 도구들은 프로젝트의 `.versions.env`로 관리되지 않으며, 개발자가 직접 설치/업데이트해야 합니다.

### 📋 필수 도구들

| 도구 | 최소 버전 | 권장 버전 | 설치 방법 | 업데이트 방법 |
|------|-----------|-----------|-----------|---------------|
| **Docker Engine** | >= 24.0 | >= 26.0 | [공식 문서](https://docs.docker.com/engine/install/) | `sudo apt upgrade docker-ce` |
| **Docker Buildx** | >= v0.25.0 | >= v0.26.1 | 자동 설치됨 | `docker buildx install` |
| **Git** | >= 2.40 | >= 2.45 | `sudo apt install git` | `sudo apt upgrade git` |

### 📋 선택적 도구들

| 도구 | 용도 | 설치 방법 |
|------|------|-----------|
| **VS Code Desktop** | 로컬 편집 (컨테이너의 VS Code Server와 별개) | [공식 다운로드](https://code.visualstudio.com/) |
| **GitHub CLI** | 로컬 Git 작업 (컨테이너 내부 버전과 별개) | `sudo apt install gh` |

## 🔧 설치 가이드

### Ubuntu/Debian 기준

```bash
# 1. Docker Engine 설치 (최신 버전)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Docker Buildx 확인 (보통 자동 설치됨)
docker buildx version

# 3. Git 업데이트
sudo apt update && sudo apt upgrade git

# 4. GitHub CLI 설치 (선택사항)
sudo apt install gh

# 5. 환경 검증
./scripts/check-dev-requirements.sh
```

### macOS 기준

```bash
# 1. Docker Desktop 설치
# https://docs.docker.com/desktop/mac/install/

# 2. Git 업데이트 (Homebrew 사용)
brew upgrade git

# 3. GitHub CLI 설치 (선택사항)  
brew install gh

# 4. 환경 검증
./scripts/check-dev-requirements.sh
```

## ⚠️ 중요 사항

### ✅ 올바른 관리 방식

1. **개발자 로컬 도구**: 직접 시스템 패키지 매니저로 관리
2. **컨테이너 도구**: `.versions.env`와 `scripts/update-container-versions.py`로 관리
3. **CI/CD 도구**: GitHub Actions 설정으로 관리

### ❌ 피해야 할 실수

```bash
# ❌ 컨테이너 도구 관리 스크립트로 로컬 도구 관리 시도
python3 scripts/update-container-versions.py  # Docker Buildx는 여기서 관리 안됨!

# ✅ 올바른 방식
sudo apt upgrade docker-buildx-plugin  # 개발자가 직접 관리
```

## 🚨 문제 해결

### Docker 관련 문제

```bash
# Docker 서비스 상태 확인
sudo systemctl status docker

# Docker 권한 문제 해결
sudo usermod -aG docker $USER
newgrp docker

# Buildx 플러그인 재설치
docker buildx install
```

### 버전 확인 방법

```bash
# 현재 설치된 버전들 확인
docker --version
docker buildx version
git --version
gh --version 2>/dev/null || echo "GitHub CLI 미설치"
```

## 🔄 정기 업데이트 권장사항

### 월간 체크리스트

- [ ] Docker Engine 보안 업데이트 확인
- [ ] Docker Buildx 새 버전 확인
- [ ] Git 업데이트 확인
- [ ] 개발 환경 검증 스크립트 실행

### 업데이트 명령어

```bash
# Ubuntu/Debian
sudo apt update
sudo apt upgrade docker-ce docker-buildx-plugin git

# macOS
brew upgrade docker git gh
```

## 📞 지원

문제가 발생하면:

1. `./scripts/check-dev-requirements.sh` 실행으로 환경 진단
2. 각 도구의 공식 문서 참조
3. 프로젝트 이슈 트래커에 문의 