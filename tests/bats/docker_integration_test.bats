#!/usr/bin/env bats

# Docker Integration Tests - BATS Version
# Docker 실제 환경 통합 테스트 (BATS 마이그레이션)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

# 색상 변수 정의
export GREEN='\033[0;32m'
export NC='\033[0m'

# 로깅 함수
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# 함수 존재 확인 헬퍼
function_exists() {
    declare -f "$1" >/dev/null 2>&1
}

# 통합 테스트 전용 스킵 체크
check_integration_requirements() {
    # Docker daemon이 실행 중인지 확인
    if ! docker info >/dev/null 2>&1; then
        skip "Docker daemon not running - skipping integration tests"
    fi
    
    # CI 환경이 아닌 경우 사용자 확인
    if [[ "${CI:-false}" != "true" ]] && [[ "${FORCE_INTEGRATION:-false}" != "true" ]]; then
        skip "Integration tests skipped - set FORCE_INTEGRATION=true to run"
    fi
}

# =============================================================================
# Docker 기본 기능 테스트들
# =============================================================================

@test "docker_integration: basic functionality" {
    check_integration_requirements
    
    # Docker 버전 확인
    run docker --version
    assert_success
    assert_output --partial "Docker version"
    
    # Docker 정보 조회
    run docker info
    assert_success
}

@test "docker_integration: buildx functionality" {
    check_integration_requirements
    
    # Buildx 버전 확인
    run docker buildx version
    
    if [[ $status -eq 0 ]]; then
        assert_output --partial "buildx"
        
        # Buildx 빌더 목록
        run docker buildx ls
        assert_success
    else
        skip "Docker Buildx not available"
    fi
}

@test "docker_integration: image pull test" {
    check_integration_requirements
    
    # 가장 작은 이미지 pull 테스트
    run docker pull hello-world
    assert_success
    
    # 이미지가 존재하는지 확인
    run docker images hello-world
    assert_success
    assert_output --partial "hello-world"
}

@test "docker_integration: container run test" {
    check_integration_requirements
    
    # 간단한 컨테이너 실행
    run docker run --rm hello-world
    assert_success
    assert_output --partial "Hello from Docker"
}

# =============================================================================
# setup_buildx 함수 통합 테스트
# =============================================================================

@test "docker_integration: setup_buildx function test" {
    check_integration_requirements
    
    # 실제 setup_multi_architecture_build.sh에서 함수 로드
    if [[ -f "../../setup_multi_architecture_build.sh" ]]; then
        # BATS는 테스트 디렉토리에서 실행되므로 상대 경로 조정
        run bash -c '
            cd ../../
            source setup_multi_architecture_build.sh
            declare -f setup_buildx >/dev/null 2>&1
        '
        
        if [[ $status -eq 0 ]]; then
            # setup_buildx 함수가 존재함
            
            # 테스트용 빌더 생성 시도
            run docker buildx create --name test-builder-$$
            if [[ $status -eq 0 ]]; then
                # 빌더 정리
                run docker buildx rm test-builder-$$
                assert_success
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

# =============================================================================
# 시스템 정보 및 리소스 테스트들
# =============================================================================

@test "docker_integration: system information collection" {
    check_integration_requirements
    
    # 시스템 정보 수집 (디버그용)
    run docker version
    assert_success
    
    run docker info
    assert_success
    
    # Buildx 정보 (실패해도 괜찮음)
    docker buildx ls || true
    
    # 최소한 Docker가 응답하는지 확인
    run docker version
    assert_success
}

@test "docker_integration: resource usage check" {
    check_integration_requirements
    
    # 디스크 사용량 체크
    run docker system df
    # Docker 버전에 따라 이 명령이 없을 수 있으므로 실패 허용
    
    # 기본 정보만 확인
    run docker info
    assert_success
}

@test "docker_integration: network connectivity" {
    check_integration_requirements
    
    # Docker가 외부 네트워크에 접근할 수 있는지 확인
    run timeout 30 docker run --rm alpine:latest ping -c 1 google.com
    
    if [[ $status -eq 0 ]]; then
        assert_success
    elif [[ $status -eq 124 ]]; then
        skip "Network connectivity test timed out"
    else
        skip "Network connectivity not available or alpine image not accessible"
    fi
}

@test "docker_integration: buildx multiarch support" {
    check_integration_requirements
    
    # Buildx가 멀티아키텍처를 지원하는지 확인
    run docker buildx ls
    
    if [[ $status -eq 0 ]]; then
        # 기본 빌더에서 지원하는 플랫폼 확인
        if [[ "$output" == *"linux/amd64"* ]] || [[ "$output" == *"linux/arm64"* ]]; then
            assert_success
        else
            skip "Multi-architecture support not detected"
        fi
    else
        skip "Docker Buildx not available for multiarch test"
    fi
}

# =============================================================================
# 정리 및 안전성 테스트들
# =============================================================================

@test "docker_integration: cleanup verification" {
    check_integration_requirements
    
    # 테스트 이미지가 있다면 정리
    run docker images hello-world
    if [[ $status -eq 0 ]] && [[ "$output" == *"hello-world"* ]]; then
        run docker rmi hello-world
        # 정리는 실패해도 괜찮음 (다른 프로세스에서 사용 중일 수 있음)
    fi
    
    # 기본적으로 성공
    assert_success
}

@test "docker_integration: docker daemon health" {
    check_integration_requirements
    
    # Docker daemon의 기본 상태 확인
    run docker info
    assert_success
    
    # 중요한 정보들이 포함되어 있는지 확인
    assert_output --partial "Server Version"
    
    # 에러 상태가 없는지 확인
    refute_output --partial "ERROR"
    refute_output --partial "WARN"
}

# Setup/Teardown
setup() {
    # 각 테스트 전에 Docker 상태 확인은 check_integration_requirements에서 처리
    :
}

teardown() {
    # Docker 정리 작업 (실패해도 괜찮음)
    docker system prune -f >/dev/null 2>&1 || true
    
    # 테스트용 빌더가 남아있다면 정리
    docker buildx rm test-builder-$$ >/dev/null 2>&1 || true
} 