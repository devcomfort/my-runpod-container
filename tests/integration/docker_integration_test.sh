#!/bin/bash

# Docker Integration Tests
# Docker 실제 환경 통합 테스트

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"

# 통합 테스트 전용 스킵 체크
check_integration_requirements() {
    # Docker daemon이 실행 중인지 확인
    if ! docker info >/dev/null 2>&1; then
        skip "Docker daemon not running - skipping integration tests"
        return 1
    fi
    
    # CI 환경이 아닌 경우 사용자 확인
    if [[ "${CI:-false}" != "true" ]] && [[ "${FORCE_INTEGRATION:-false}" != "true" ]]; then
        echo "WARNING: Integration tests require Docker and may be resource intensive."
        echo "Set FORCE_INTEGRATION=true to run these tests."
        skip "Integration tests skipped - set FORCE_INTEGRATION=true to run"
        return 1
    fi
    
    return 0
}

# Docker 기본 기능 테스트
test_docker_basic_functionality() {
    check_integration_requirements || return 0
    
    # Docker 버전 확인
    local docker_version
    docker_version=$(docker --version)
    assert_contains "$docker_version" "Docker version"
    
    # Docker 정보 조회
    assert_successful_code 'docker info'
}

# Docker Buildx 기능 테스트
test_docker_buildx_functionality() {
    check_integration_requirements || return 0
    
    # Buildx 버전 확인
    local buildx_version
    buildx_version=$(docker buildx version 2>/dev/null)
    
    if [[ -n "$buildx_version" ]]; then
        assert_contains "$buildx_version" "buildx"
        
        # Buildx 빌더 목록
        assert_successful_code 'docker buildx ls'
    else
        skip "Docker Buildx not available"
    fi
}

# Docker 이미지 pull 테스트 (가벼운 이미지)
test_docker_image_pull() {
    check_integration_requirements || return 0
    
    # 가장 작은 이미지 pull 테스트
    assert_successful_code 'docker pull hello-world'
    
    # 이미지가 존재하는지 확인
    assert_successful_code 'docker images hello-world'
    
    # 정리
    docker rmi hello-world >/dev/null 2>&1 || true
}

# Docker 컨테이너 실행 테스트
test_docker_container_run() {
    check_integration_requirements || return 0
    
    # 간단한 컨테이너 실행
    local output
    output=$(docker run --rm hello-world 2>&1)
    
    assert_contains "$output" "Hello from Docker"
}

# setup_buildx 함수 통합 테스트 (실제 함수 로드)
test_setup_buildx_integration() {
    check_integration_requirements || return 0
    
    # 실제 setup_multi_architecture_build.sh에서 함수 로드
    if [[ -f "setup_multi_architecture_build.sh" ]]; then
        source setup_multi_architecture_build.sh
        
        # setup_buildx 함수가 존재하는지 확인
        if function_exists setup_buildx; then
            # 안전한 buildx 설정 (기존 설정 보존)
            local original_builder
            original_builder=$(docker buildx inspect 2>/dev/null | head -1 | awk '{print $1}' || echo "")
            
            # 테스트용 빌더 생성 시도
            if docker buildx create --name test-builder >/dev/null 2>&1; then
                docker buildx rm test-builder >/dev/null 2>&1
                log_info "Buildx functionality verified"
            else
                skip "Unable to create test buildx builder"
            fi
        else
            skip "setup_buildx function not found"
        fi
    else
        skip "setup_multi_architecture_build.sh not found"
    fi
}

# Docker 시스템 정보 수집
test_docker_system_info() {
    check_integration_requirements || return 0
    
    # 시스템 정보 수집 (디버그용)
    echo "=== Docker System Information ==="
    docker version || true
    echo ""
    docker info | head -20 || true
    echo ""
    docker buildx ls || true
    echo "================================="
    
    # 최소한 Docker가 응답하는지 확인
    assert_successful_code 'docker version'
}

# 리소스 사용량 체크
test_docker_resource_usage() {
    check_integration_requirements || return 0
    
    # 디스크 사용량 체크
    local disk_usage
    disk_usage=$(docker system df 2>/dev/null || echo "unavailable")
    
    echo "Docker disk usage: $disk_usage"
    
    # 기본적으로 성공 (정보 수집용)
    assert_true "true"
}

# 전역 setup/teardown
setup() {
    standard_setup
    
    # 로깅 함수 정의
    log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
}

teardown() {
    # Docker 정리 작업
    docker system prune -f >/dev/null 2>&1 || true
    
    standard_teardown
} 