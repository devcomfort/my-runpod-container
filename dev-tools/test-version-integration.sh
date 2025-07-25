#!/bin/bash

# 버전 통합 테스트 스크립트
# .versions.env의 버전들이 모든 빌드 시스템에 올바르게 반영되는지 확인

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로깅 함수
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }

# 테스트 결과 변수
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 함수
run_test() {
    local test_name="$1"
    local expected="$2" 
    local actual="$3"
    
    log_test "Testing: $test_name"
    
    if [ "$expected" = "$actual" ]; then
        log_info "✅ PASS: $test_name ($actual)"
        ((TESTS_PASSED++))
    else
        log_error "❌ FAIL: $test_name"
        log_error "   Expected: $expected"
        log_error "   Actual: $actual"
        ((TESTS_FAILED++))
    fi
    echo
}

echo "🔬 버전 통합 테스트 시작"
echo "======================================"

# .versions.env 파일 존재 확인 (상위 디렉토리에서)
if [ ! -f "../.versions.env" ]; then
    log_error "../.versions.env 파일을 찾을 수 없습니다!"
    exit 1
fi

log_info "✅ ../.versions.env 파일 발견"

# 환경변수 로드 (상위 디렉토리에서)
set -a
source ../.versions.env
set +a

log_info "환경변수 로드 완료"
echo

# 1. Python 버전 스크립트 존재 테스트
log_test "1. Python 버전 스크립트 존재 테스트"
if [ -f "scripts/update-versions.py" ] && python3 -c "import sys; print('OK')" >/dev/null 2>&1; then
    log_info "✅ Python 스크립트 파일 존재 및 Python 환경 정상"
    ((TESTS_PASSED++))
else
    log_error "❌ Python 스크립트 또는 Python 환경 문제"
    ((TESTS_FAILED++))
fi
echo

# 2. Docker Bake 설정 파일 테스트
log_test "2. Docker Bake 설정 파일 테스트"

if [ -f "../docker-bake.hcl" ]; then
    # docker-bake.hcl에서 변수 기본값 확인 (상위 디렉토리에서)
    BAKE_GO=$(grep -A2 'variable "GO_VERSION"' ../docker-bake.hcl | grep 'default' | sed 's/.*= "\([^"]*\)".*/\1/')
    BAKE_TINYGO=$(grep -A2 'variable "TINYGO_VERSION"' ../docker-bake.hcl | grep 'default' | sed 's/.*= "\([^"]*\)".*/\1/')
    BAKE_GH=$(grep -A2 'variable "GH_VERSION"' ../docker-bake.hcl | grep 'default' | sed 's/.*= "\([^"]*\)".*/\1/')
    
    run_test "Docker Bake GO_VERSION (default)" "$GO_VERSION" "$BAKE_GO"
    run_test "Docker Bake TINYGO_VERSION (default)" "$TINYGO_VERSION" "$BAKE_TINYGO"
    run_test "Docker Bake GH_VERSION (default)" "$GH_VERSION" "$BAKE_GH"
else
    log_error "❌ ../docker-bake.hcl 파일을 찾을 수 없습니다"
    ((TESTS_FAILED++))
fi

# 3. Dockerfile ARG 테스트
log_test "3. Dockerfile ARG 버전 테스트"

if [ -f "../Dockerfile" ]; then
    DOCKERFILE_GO=$(grep -E "^ARG GO_VERSION=" ../Dockerfile | cut -d'"' -f2)
    DOCKERFILE_TINYGO=$(grep -E "^ARG TINYGO_VERSION=" ../Dockerfile | cut -d'"' -f2)
    DOCKERFILE_GH=$(grep -E "^ARG GH_VERSION=" ../Dockerfile | cut -d'"' -f2)
    
    run_test "Dockerfile GO_VERSION" "$GO_VERSION" "$DOCKERFILE_GO"
    run_test "Dockerfile TINYGO_VERSION" "$TINYGO_VERSION" "$DOCKERFILE_TINYGO"
    run_test "Dockerfile GH_VERSION" "$GH_VERSION" "$DOCKERFILE_GH"
else
    log_error "❌ ../Dockerfile을 찾을 수 없습니다"
    ((TESTS_FAILED++))
fi

# 4. setup_multi_architecture_build.sh 테스트
log_test "4. BuildX 스크립트 버전 로드 테스트"

if [ -f "setup_multi_architecture_build.sh" ]; then
    # 임시로 스크립트 시뮬레이션 (실제 실행 없이 버전 로드만 테스트)
    BUILDX_SCRIPT_VERSION=$(grep -E "BUILDX_VERSION=\\\$\{BUILDX_VERSION:-" setup_multi_architecture_build.sh | sed 's/.*:-"\([^"]*\)".*/\1/')
    
    run_test "BuildX Script BUILDX_VERSION" "$BUILDX_VERSION" "$BUILDX_SCRIPT_VERSION"
else
    log_error "❌ setup_multi_architecture_build.sh를 찾을 수 없습니다"
    ((TESTS_FAILED++))
fi

# 테스트 결과 요약
echo "======================================"
echo "🎯 테스트 결과 요약"
echo "======================================"
log_info "✅ 통과: $TESTS_PASSED개"
if [ $TESTS_FAILED -gt 0 ]; then
    log_error "❌ 실패: $TESTS_FAILED개"
    echo
    log_warn "🔧 실패한 테스트가 있습니다. 다음 명령으로 동기화를 시도하세요:"
    echo "   python3 scripts/update-versions.py"
    exit 1
else
    log_info "🎉 모든 테스트가 통과했습니다!"
    echo
    log_info "📊 현재 버전 상태:"
    echo "   GO_VERSION=$GO_VERSION"
    echo "   TINYGO_VERSION=$TINYGO_VERSION"
    echo "   GH_VERSION=$GH_VERSION"
    echo "   BUILDX_VERSION=$BUILDX_VERSION"
    exit 0
fi 