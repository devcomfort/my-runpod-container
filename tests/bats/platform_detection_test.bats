#!/usr/bin/env bats

# Platform Detection Functions Unit Tests
# 플랫폼 감지 및 CI 환경 감지 함수들의 단위 테스트 (BATS 버전)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper/bats-file/load'

# 프로젝트 루트 설정
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

# 플랫폼 감지 함수 정의
detect_platform() {
    local arch os
    arch=$(uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown")
    os=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown")
    
    local PLATFORM_ARCH PLATFORM_OS
    
    case $arch in
        x86_64|amd64)
            PLATFORM_ARCH="amd64"
            ;;
        aarch64|arm64)
            PLATFORM_ARCH="arm64"
            ;;
        armv7l)
            PLATFORM_ARCH="arm"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
    
    case $os in
        linux)
            PLATFORM_OS="linux"
            ;;
        darwin)
            PLATFORM_OS="darwin"
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            return 1
            ;;
    esac
    
    PLATFORM="${PLATFORM_OS}-${PLATFORM_ARCH}"
    export PLATFORM PLATFORM_OS PLATFORM_ARCH
    
    echo "$PLATFORM"
    return 0
}

# CI 환경 감지 함수 정의  
is_ci_environment() {
    [[ "${CI:-false}" == "true" ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]
}

# Mock 함수들 - BATS 스타일
setup() {
    # 각 테스트 전에 실행
    export PATH="$BATS_TEST_DIRNAME:$PATH"
}

teardown() {
    # 각 테스트 후에 정리
    unset PLATFORM PLATFORM_OS PLATFORM_ARCH
}

# 테스트 시작

@test "detect_platform detects linux-amd64 correctly" {
    # Linux x86_64 환경 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "x86_64"
        elif [[ "$1" == "-s" ]]; then
            echo "Linux"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_success
    assert_output "linux-amd64"
}

@test "detect_platform detects linux-arm64 correctly" {
    # Linux aarch64 환경 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "aarch64"
        elif [[ "$1" == "-s" ]]; then
            echo "Linux"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_success
    assert_output "linux-arm64"
}

@test "detect_platform detects darwin-amd64 correctly" {
    # macOS x86_64 환경 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "x86_64"
        elif [[ "$1" == "-s" ]]; then
            echo "Darwin"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_success
    assert_output "darwin-amd64"
}

@test "detect_platform handles unsupported architecture" {
    # 지원되지 않는 아키텍처 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "sparc"
        elif [[ "$1" == "-s" ]]; then
            echo "Linux"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_failure
    assert_output --partial "Unsupported architecture: sparc"
}

@test "detect_platform handles unsupported OS" {
    # 지원되지 않는 OS 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "x86_64"
        elif [[ "$1" == "-s" ]]; then
            echo "FreeBSD"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_failure
    assert_output --partial "Unsupported OS: freebsd"
}

@test "detect_platform handles uname command failure" {
    # uname 명령어 실패 모킹 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "unknown"
        elif [[ "$1" == "-s" ]]; then
            echo "unknown"
        else
            return 1
        fi
    }
    export -f uname
    
    run detect_platform
    assert_failure
    assert_output --partial "Unsupported architecture: unknown"
}

@test "detect_platform is case insensitive" {
    # 대소문자 구분 없이 처리하는지 테스트 - BATS 스타일
    function uname() {
        if [[ "$1" == "-m" ]]; then
            echo "X86_64"
        elif [[ "$1" == "-s" ]]; then
            echo "Linux"
        else
            command uname "$@"
        fi
    }
    export -f uname
    
    run detect_platform
    assert_success
    assert_output "linux-amd64"
}

# CI 환경 감지 테스트

@test "is_ci_environment detects GitHub Actions" {
    # GitHub Actions 환경 모킹
    export GITHUB_ACTIONS="true"
    unset CI
    
    run is_ci_environment
    assert_success
}

@test "is_ci_environment detects CI variable" {
    # CI 환경변수 모킹
    export CI="true"
    unset GITHUB_ACTIONS
    
    run is_ci_environment
    assert_success
}

@test "is_ci_environment detects multiple indicators" {
    # 여러 CI 환경변수가 설정된 경우
    export CI="true"
    export GITHUB_ACTIONS="true"
    
    run is_ci_environment
    assert_success
}

@test "is_ci_environment returns false in non-CI environment" {
    # 모든 CI 환경변수 제거
    unset CI GITHUB_ACTIONS
    
    run is_ci_environment
    assert_failure
} 