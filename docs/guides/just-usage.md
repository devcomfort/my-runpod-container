# 🚀 Just 명령 실행기 사용 가이드

## 📋 개요

[Just](https://github.com/casey/just)는 Make의 복잡함을 피하면서 프로젝트의 명령어들을 간단하고 직관적으로 관리할 수 있는 도구입니다. 이 프로젝트에서는 Makefile을 대체하여 더 나은 개발 경험을 제공합니다.

## 📦 설치 방법

### Ubuntu/Debian
```bash
# 패키지 매니저로 설치
sudo apt update
sudo apt install just

# 또는 최신 버전을 위해 Rust/Cargo로 설치
cargo install just
```

### macOS
```bash
# Homebrew로 설치
brew install just

# 또는 MacPorts로 설치
sudo port install just
```

### Windows
```bash
# Chocolatey로 설치
choco install just

# 또는 Scoop으로 설치
scoop install just
```

### 바이너리 다운로드
```bash
# 최신 릴리스 다운로드 (Linux x64)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin

# PATH에 추가
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 🎯 기본 사용법

### 📋 사용 가능한 명령어 보기
```bash
# 모든 명령어 목록 표시
just

# 또는
just --list
```

### 🚀 주요 명령어

#### **개발 환경 설정**
```bash
# 개발 환경 전체 체크 및 설정
just dev-setup

# 개발 환경 요구사항 체크
just check-env

# 버전 일관성 체크
just check-versions
```

#### **Docker 빌드**
```bash
# CPU 버전 빌드 (가장 자주 사용)
just cpu

# 모든 타겟 빌드
just build

# 특정 타겟 빌드
just build-target 12-6-2

# 순차 빌드 (리소스 절약)
just build-seq
```

#### **테스트 실행**
```bash
# 빠른 테스트 (unit only)
just test

# 모든 테스트
just test-all

# 특정 테스트 타입
just test-shell --unit-only
just test-shell --mocked-only
just test-shell --integration
```

#### **통합 개발 워크플로우**
```bash
# 빌드 + 테스트
just build-test

# CI 파이프라인 시뮬레이션
just ci

# 프로젝트 상태 확인
just status
just info
```

#### **유지보수**
```bash
# 도커 리소스 정리
just clean

# 전체 정리
just clean-all

# 빌드 캐시 정리
just clean-cache
```

## 🔧 환경 변수

Just는 환경 변수를 통해 설정을 커스터마이징할 수 있습니다:

```bash
# 디버그 모드 활성화
DEBUG=1 just build

# 릴리스 버전 설정
RELEASE=0.4 just build

# Docker Hub 사용자명 설정
DOCKER_HUB_USERNAME=myusername just push
```

## 🆚 Make vs Just 비교

### **Makefile (이전)**
```makefile
# 복잡한 문법
.PHONY: build
build:
	@docker buildx bake --file docker-bake.hcl $(DEBUG_FLAG)

# 조건문이 복잡함
ifdef DEBUG
  ifeq ($(DEBUG), 1)
    DEBUG_FLAG = --debug
  else
    DEBUG_FLAG =
  endif
else
  DEBUG_FLAG =
endif
```

### **justfile (현재)**
```just
# 간단하고 직관적인 문법
build:
    @echo "🐳 모든 도커 이미지 빌드 시작..."
    docker buildx bake --file docker-bake.hcl {{debug_flag}}

# 조건문이 간단함
debug_flag := if debug_mode == "1" { "--debug" } else { "" }
```

## ✨ Just의 장점

### **1. 간단한 문법**
- 모든 레시피는 기본적으로 `.PHONY` 타겟으로 처리
- `$$` 없이 환경 변수 사용 가능
- 직관적인 변수 및 조건문 문법

### **2. 더 나은 에러 메시지**
```bash
# Make
$ make test
make: `test' is up to date.

# Just
$ just test
🧪 Shell 테스트 실행...
./run_shell_tests.sh --unit-only
```

### **3. 풍부한 기능**
- 명령줄 인자 지원: `just test-shell --verbose`
- 기본값 설정: `build-test target="cpu"`
- 환경 변수 기본값: `env_var_or_default('DEBUG', '0')`

### **4. 교차 플랫폼 호환성**
- Linux, macOS, Windows에서 동일하게 작동
- Make의 플랫폼별 차이점 없음

## 🎓 고급 사용법

### **의존성 체인**
```just
# 명령어 의존성
all-seq: build-seq push-seq
    @echo "🎉 모든 순차 작업 완료!"

# 명령어 호출
cpu: (build-target "cpu")
```

### **매개변수 사용**
```just
# 필수 매개변수
build-target target:
    docker buildx bake {{target}} --file docker-bake.hcl

# 선택적 매개변수
test-shell *args="":
    ./run_shell_tests.sh {{args}}

# 기본값이 있는 매개변수
build-test target="cpu":
    just build-target {{target}}
    just test-shell --unit-only
```

### **스크립트 블록**
```just
build-seq:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=({{targets}})
    for target in "${targets[@]}"; do
        echo "=== $target 빌드 시작 ==="
        docker buildx bake "$target" --file docker-bake.hcl || exit 1
    done
```

## 📚 추가 자료

- **공식 문서**: https://just.systems/
- **GitHub 저장소**: https://github.com/casey/just
- **예제 justfile들**: https://github.com/casey/just/tree/master/examples

## 🔗 관련 문서

- [개발 가이드](development.md)
- [Shell 테스트 시스템](../shell-testing.md)
- [도구 관리](tool-management.md) 