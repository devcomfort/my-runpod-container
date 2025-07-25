# 🐳 Personal RunPod Development Environment - Just Commands
# Just는 Make보다 간단하고 직관적인 명령 실행기입니다
# 사용법: just <command> 또는 just --list

# === 기본 설정 ===
# 환경 변수로 오버라이드 가능
release := env_var_or_default('RELEASE', '0.3')
docker_hub_username := env_var_or_default('DOCKER_HUB_USERNAME', 'devcomfort')
debug_mode := env_var_or_default('DEBUG', '0')

# 빌드 대상 목록
targets := "cpu 11-1-1 11-8-0 12-1-0 12-2-0 12-4-1 12-5-1 12-6-2"

# 디버그 플래그 계산
debug_flag := if debug_mode == "1" { "--debug" } else { "" }

# === 기본 명령어 (just 실행 시 표시) ===
default:
	@just --list

# 도움말 표시
help:
	@echo "🐳 Personal RunPod Development Environment - Just Commands"
	@echo ""
	@echo "📋 사용 가능한 명령어:"
	@echo "  just                     : 이 도움말을 표시합니다"
	@echo "  just build              : 모든 도커 이미지를 빌드합니다"
	@echo "  just build-target <타겟> : 특정 타겟을 빌드합니다 (예: just build-target cpu)"
	@echo "  just push               : 모든 도커 이미지를 푸시합니다"
	@echo "  just push-target <타겟>  : 특정 타겟을 푸시합니다 (예: just push-target cpu)"
	@echo "  just build-seq          : 모든 타겟을 순차적으로 빌드합니다"
	@echo "  just push-seq           : 모든 타겟을 순차적으로 푸시합니다"
	@echo "  just all-seq            : 모든 타겟에 대해 빌드와 푸시를 순차적으로 수행합니다"
	@echo "  just clean              : 모든 도커 리소스를 정리합니다"
	@echo "  just test-shell         : Shell 테스트를 실행합니다"
	@echo "  just check-env          : 개발 환경을 체크합니다"
	@echo ""
	@echo "🎯 빠른 개발 명령어:"
	@echo "  just dev-setup          : 개발 환경 전체 설정"
	@echo "  just build-test         : 빌드 + 테스트 실행"
	@echo "  just ci                 : CI 파이프라인과 동일한 검사"
	@echo ""
	@echo "�� 환경 변수:"
	@echo "  DEBUG=1                 : 디버그 모드 활성화 (예: DEBUG=1 just build)"
	@echo "  RELEASE={{release}}            : 현재 릴리스 버전"
	@echo "  DOCKER_HUB_USERNAME={{docker_hub_username}} : 현재 Docker Hub 사용자명"

# === Docker 빌드 명령어 ===

# 모든 도커 이미지 빌드
build:
	@echo "🐳 모든 도커 이미지 빌드 시작..."
	@echo "�� 설정: RELEASE={{release}}, DEBUG={{debug_mode}}"
	docker buildx bake --file docker-bake.hcl {{debug_flag}}

# 특정 타겟 빌드
build-target target:
	@echo "🎯 {{target}} 타겟 빌드 시작..."
	docker buildx bake {{target}} --file docker-bake.hcl {{debug_flag}}

# 순차 빌드 (리소스 절약)
build-seq:
	@echo "📦 순차 빌드 시작..."
	#!/usr/bin/env bash
	set -euo pipefail
	targets=({{targets}})
	for target in "${targets[@]}"; do
	echo "=== $target 빌드 시작 ==="
	docker buildx bake "$target" --file docker-bake.hcl {{debug_flag}} || exit 1
	echo "✅ $target 빌드 완료"
	done

# === Docker 푸시 명령어 ===

# 모든 도커 이미지 푸시
push:
	@echo "🚀 모든 도커 이미지 푸시 시작..."
	docker buildx bake --file docker-bake.hcl --push {{debug_flag}}

# 특정 타겟 푸시
push-target target:
	@echo "🎯 {{target}} 타겟 푸시 시작..."
	docker buildx bake {{target}} --file docker-bake.hcl --push {{debug_flag}}

# 순차 푸시
push-seq:
	@echo "📤 순차 푸시 시작..."
	#!/usr/bin/env bash
	set -euo pipefail
	targets=({{targets}})
	for target in "${targets[@]}"; do
	echo "=== $target 푸시 시작 ==="
	docker buildx bake "$target" --file docker-bake.hcl --push {{debug_flag}} || exit 1
	echo "✅ $target 푸시 완료"
	done

# 순차 전체 작업 (빌드 + 푸시)
all-seq: build-seq push-seq
	@echo "🎉 모든 순차 작업 완료!"

# === 개발 및 테스트 명령어 ===

# Shell 테스트 실행
test-shell *args="":
	@echo "�� Shell 테스트 실행..."
	./run_shell_tests.sh {{args}}

# 개발 환경 체크
check-env:
	@echo "🔍 개발 환경 체크..."
	./dev-tools/check-dev-requirements.sh

# 버전 일관성 체크
check-versions:
	@echo "🔧 버전 일관성 체크..."
	./dev-tools/simple-version-test.sh

# 컨테이너 버전 업데이트
update-versions:
	@echo "📋 컨테이너 버전 업데이트..."
	python3 dev-tools/update-container-versions.py

# === 통합 개발 명령어 ===

# 개발 환경 전체 설정
dev-setup:
	@echo "🚀 개발 환경 전체 설정 시작..."
	just check-env
	just check-versions
	@echo "✅ 개발 환경 설정 완료!"

# 빌드 + 테스트
build-test target="cpu":
	@echo "🔄 빌드 + 테스트 파이프라인 시작..."
	just build-target {{target}}
	just test-shell --unit-only
	@echo "✅ 빌드 + 테스트 완료!"

# CI 파이프라인과 동일한 검사
ci:
	@echo "🤖 CI 파이프라인 시뮬레이션..."
	just test-shell --verbose
	just check-env
	just check-versions
	@echo "✅ CI 검사 완료!"

# === 유지보수 명령어 ===

# 도커 리소스 정리
clean:
	@echo "🧹 도커 리소스 정리..."
	docker system prune -f
	@echo "✅ 정리 완료!"

# 전체 정리 (더 강력한 정리)
clean-all:
	@echo "💥 전체 도커 리소스 정리..."
	docker system prune -af --volumes
	@echo "✅ 전체 정리 완료!"

# 빌드 캐시 정리
clean-cache:
	@echo "🗑️ 빌드 캐시 정리..."
	docker builder prune -f
	@echo "✅ 캐시 정리 완료!"

# === 편의 명령어 ===

# CPU 전용 빌드 (가장 자주 사용)
cpu: (build-target "cpu")

# CUDA 최신 버전 빌드
cuda: (build-target "12-6-2")

# 빠른 테스트 (unit only)
test: (test-shell "--unit-only")

# 모든 테스트
test-all: (test-shell "--verbose")

# 프로젝트 상태 확인
status:
	@echo "📊 프로젝트 상태:"
	@echo "  RELEASE: {{release}}"
	@echo "  DOCKER_HUB_USERNAME: {{docker_hub_username}}"
	@echo "  DEBUG: {{debug_mode}}"
	@echo "  사용 가능한 타겟: {{targets}}"
	@echo ""
	@git --no-pager log --oneline -3 || echo "Git 히스토리 없음"

# Git 상태와 함께 프로젝트 정보
info:
	@echo "ℹ️ 프로젝트 정보:"
	@echo "📁 현재 디렉토리: $(pwd)"
	@echo "🏷️ Git 브랜치: $(git branch --show-current 2>/dev/null || echo 'N/A')"
	@echo "🔄 Git 상태:"
	@git --no-pager status --porcelain || echo "Git 없음"
	@echo ""
	just status
