#!/bin/bash

# Platform Detection Functions Unit Tests
# 플랫폼 감지 및 CI 환경 감지 함수들의 단위 테스트

# 테스트 헬퍼 및 모킹 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"
source "$PROJECT_ROOT/tests/helpers/mock_commands.sh"

# 플랫폼 감지 함수 정의
define_detect_platform() {
    detect_platform() {
        local arch os
        arch=$(uname -m 2>/dev/null || echo "unknown")
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
        echo "Detected platform: $PLATFORM"
    }
}

# CI 환경 감지 함수 정의
define_is_ci_environment() {
    is_ci_environment() {
        [[ "${CI:-false}" == "true" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]
    }
}

# Linux x86_64 플랫폼 테스트
test_detect_platform_linux_x86() {
    mock_uname_linux_x86
    
    # 함수 실행
    detect_platform
    
    # 결과 검증
    assert_equals "linux-amd64" "$PLATFORM"
    assert_equals "linux" "$PLATFORM_OS"
    assert_equals "amd64" "$PLATFORM_ARCH"
}

# Linux ARM64 플랫폼 테스트
test_detect_platform_linux_arm() {
    mock_uname_linux_arm
    
    detect_platform
    
    assert_equals "linux-arm64" "$PLATFORM"
    assert_equals "linux" "$PLATFORM_OS"
    assert_equals "arm64" "$PLATFORM_ARCH"
}

# macOS 플랫폼 테스트
test_detect_platform_macos() {
    mock_uname_macos
    
    detect_platform
    
    assert_equals "darwin-amd64" "$PLATFORM"
    assert_equals "darwin" "$PLATFORM_OS"
    assert_equals "amd64" "$PLATFORM_ARCH"
}

# ARMv7 플랫폼 테스트
test_detect_platform_armv7() {
    function uname() {
        case "$1" in
            "-m") echo "armv7l" ;;
            "-s") echo "Linux" ;;
            *) echo "Linux" ;;
        esac
    }
    export -f uname
    
    detect_platform
    
    assert_equals "linux-arm" "$PLATFORM"
    assert_equals "linux" "$PLATFORM_OS"
    assert_equals "arm" "$PLATFORM_ARCH"
}

# 지원하지 않는 아키텍처 테스트
test_detect_platform_unsupported_arch() {
    function uname() {
        case "$1" in
            "-m") echo "mips64" ;;
            "-s") echo "Linux" ;;
        esac
    }
    export -f uname
    
    # 실패해야 함
    assert_exit_code 1 'detect_platform'
}

# 지원하지 않는 OS 테스트
test_detect_platform_unsupported_os() {
    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "FreeBSD" ;;
        esac
    }
    export -f uname
    
    # 실패해야 함
    assert_exit_code 1 'detect_platform'
}

# uname 명령어 실패 테스트
test_detect_platform_uname_failure() {
    function uname() {
        echo "uname: command not found" >&2
        return 127
    }
    export -f uname
    
    detect_platform
    
    # unknown으로 처리되어 실패해야 함
    assert_exit_code 1 'detect_platform'
}

# CI 환경 감지 - GitHub Actions
test_is_ci_environment_github_actions() {
    # GitHub Actions 환경 모킹
    mock_env_var "GITHUB_ACTIONS" "true"
    unset CI GITLAB_CI
    
    assert_true 'is_ci_environment'
}

# CI 환경 감지 - CI 변수
test_is_ci_environment_ci_variable() {
    # CI 환경변수 모킹
    mock_env_var "CI" "true"
    unset GITHUB_ACTIONS GITLAB_CI
    
    assert_true 'is_ci_environment'
}

# CI 환경 감지 - GitLab CI
test_is_ci_environment_gitlab_ci() {
    # GitLab CI 환경 모킹
    mock_env_var "GITLAB_CI" "true"
    unset GITHUB_ACTIONS CI
    
    assert_true 'is_ci_environment'
}

# CI 환경 감지 - 복합 환경
test_is_ci_environment_multiple_indicators() {
    # 여러 CI 환경변수가 설정된 경우
    mock_env_vars "CI=true" "GITHUB_ACTIONS=true" "GITLAB_CI=true"
    
    assert_true 'is_ci_environment'
}

# 비 CI 환경 테스트
test_is_ci_environment_not_ci() {
    # 모든 CI 환경변수 제거
    unset CI GITHUB_ACTIONS GITLAB_CI
    
    assert_false 'is_ci_environment'
}

# CI 환경 감지 - false 값
test_is_ci_environment_false_values() {
    # CI가 false로 설정된 경우
    mock_env_vars "CI=false" "GITHUB_ACTIONS=" "GITLAB_CI="
    
    assert_false 'is_ci_environment'
}

# CI 환경 감지 - 빈 문자열
test_is_ci_environment_empty_values() {
    # 빈 문자열인 경우 (GITHUB_ACTIONS, GITLAB_CI는 존재만 해도 true)
    mock_env_vars "CI=" "GITHUB_ACTIONS=" "GITLAB_CI="
    
    # GITHUB_ACTIONS와 GITLAB_CI는 빈 문자열이어도 설정되어 있으면 true
    # 하지만 우리 구현에서는 -n으로 체크하므로 false여야 함
    assert_false 'is_ci_environment'
}

# 플랫폼 감지 후 환경변수 export 확인
test_detect_platform_exports_variables() {
    mock_uname_linux_x86
    
    # 변수가 export되지 않은 상태에서 시작
    unset PLATFORM PLATFORM_OS PLATFORM_ARCH
    
    detect_platform
    
    # export된 변수들이 접근 가능한지 확인
    assert_not_empty "$PLATFORM"
    assert_not_empty "$PLATFORM_OS"  
    assert_not_empty "$PLATFORM_ARCH"
}

# 연속 실행 테스트 (상태 유지)
test_detect_platform_consecutive_runs() {
    # 첫 번째 실행 - Linux
    mock_uname_linux_x86
    detect_platform
    local first_platform="$PLATFORM"
    
    # 두 번째 실행 - macOS로 변경
    mock_uname_macos
    detect_platform
    local second_platform="$PLATFORM"
    
    # 각각 다른 결과여야 함
    assert_equals "linux-amd64" "$first_platform"
    assert_equals "darwin-amd64" "$second_platform"
    assert_not_equals "$first_platform" "$second_platform"
}

# 대소문자 처리 테스트
test_detect_platform_case_insensitive() {
    function uname() {
        case "$1" in
            "-m") echo "X86_64" ;;  # 대문자
            "-s") echo "LINUX" ;;   # 대문자
        esac
    }
    export -f uname
    
    detect_platform
    
    # 소문자로 변환되어 처리되어야 함
    assert_equals "linux-amd64" "$PLATFORM"
}

# 전역 setup/teardown
setup() {
    standard_setup
    
    # 실제 스크립트에서 함수 로드 시도
    if [[ -f "setup_multi_architecture_build.sh" ]]; then
        source <(sed -n '/^detect_platform() {/,/^}/p' setup_multi_architecture_build.sh) 2>/dev/null || define_detect_platform
        source <(sed -n '/^is_ci_environment() {/,/^}/p' setup_multi_architecture_build.sh) 2>/dev/null || define_is_ci_environment
    else
        define_detect_platform
        define_is_ci_environment
    fi
}

teardown() {
    # 테스트에서 설정한 변수들 정리
    unset PLATFORM PLATFORM_OS PLATFORM_ARCH
    unset CI GITHUB_ACTIONS GITLAB_CI
    
    standard_teardown
} 