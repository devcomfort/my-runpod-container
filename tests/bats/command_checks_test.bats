#!/usr/bin/env bats

# Command Checks Unit Tests (with Mocking) - BATS Version
# 모킹을 사용한 명령어 체크 함수들의 테스트 (BATS 마이그레이션)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

# 색상 변수 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# 로깅 함수들 정의
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }

# 전역 변수
CHECKS_FAILED=0

# check_command 함수 정의 (원본에서 복사)
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$cmd is not installed. Please install it first."
        return 1
    fi
    log_info "$cmd is available"
    return 0
}

# run_check 함수 정의 (원본에서 복사)
run_check() {
    local check_name="$1"
    local command="$2"
    local min_version="$3"
    local recommended_version="$4"
    
    log_check "검사 중: $check_name"
    
    if ! command -v "${command%% *}" >/dev/null 2>&1; then
        log_error "❌ $check_name 미설치"
        echo "   설치 방법: dev-requirements.md 참조"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    # 버전 추출
    local version
    case $command in
        "docker --version")
            version=$(docker --version | sed 's/Docker version \([0-9.]*\).*/\1/')
            ;;
        "docker buildx version")
            if ! docker buildx version >/dev/null 2>&1; then
                log_error "❌ Docker Buildx 미설치 또는 실행 불가"
                ((CHECKS_FAILED++))
                return 1
            fi
            version=$(docker buildx version | head -1 | sed 's/.*v\([0-9.]*\).*/\1/')
            ;;
        "git --version")
            version=$(git --version | sed 's/git version \([0-9.]*\).*/\1/')
            ;;
        *)
            log_error "❌ 알 수 없는 명령어: $command"
            ((CHECKS_FAILED++))
            return 1
            ;;
    esac
    
    # 버전 비교 (간단 버전)
    log_info "✅ $check_name: $version"
    return 0
}

# =============================================================================
# Mock 함수들 정의
# =============================================================================

# Docker 성공 모킹
mock_docker_success() {
    function docker() {
        case "$1" in
            "--version")
                echo "Docker version 24.0.1, build abc123"
                return 0
                ;;
            "buildx")
                case "$2" in
                    "version")
                        echo "github.com/docker/buildx v0.11.2 def456"
                        return 0
                        ;;
                esac
                ;;
        esac
    }
    export -f docker
}

# Git 성공 모킹
mock_git_success() {
    function git() {
        case "$1" in
            "--version")
                echo "git version 2.34.1"
                return 0
                ;;
        esac
    }
    export -f git
}

# command 성공 모킹
mock_command_success() {
    function command() {
        case "$1" in
            "-v")
                case "$2" in
                    "docker"|"git"|"python3"|"uname"|"unknown")
                        echo "/usr/bin/$2"
                        return 0
                        ;;
                    *)
                        return 1
                        ;;
                esac
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f command
}

# command 실패 모킹
mock_command_failure() {
    function command() {
        return 1
    }
    export -f command
}

# 특정 도구만 실패하도록 모킹
mock_missing_tool() {
    local tool="$1"
    
    function command() {
        case "$1" in
            "-v")
                case "$2" in
                    "$tool")
                        return 1
                        ;;
                    "docker"|"git"|"python3"|"uname")
                        echo "/usr/bin/$2"
                        return 0
                        ;;
                    *)
                        return 1
                        ;;
                esac
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f command
}

# =============================================================================
# check_command 테스트들
# =============================================================================

@test "check_command: success cases" {
    # Mock 설정
    mock_command_success
    
    # Docker 체크
    run check_command "docker"
    assert_success
    
    # Git 체크 
    run check_command "git"
    assert_success
    
    # Python 체크
    run check_command "python3"
    assert_success
}

@test "check_command: failure cases" {
    # Mock 설정
    mock_command_failure
    
    # 존재하지 않는 명령어
    run check_command "nonexistent_tool"
    assert_failure
    
    run check_command "docker"
    assert_failure
}

@test "check_command: missing specific tool" {
    # Docker만 없고 다른 도구는 있음 - 직접 mock 정의
    function command() {
        case "$1" in
            "-v")
                case "$2" in
                    "docker")
                        return 1
                        ;;
                    "git"|"python3"|"uname")
                        echo "/usr/bin/$2"
                        return 0
                        ;;
                    *)
                        return 1
                        ;;
                esac
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f command
    
    run check_command "docker"
    assert_failure
    
    run check_command "git"
    assert_success
}

@test "check_command: log output verification" {
    # Mock 설정
    mock_command_success
    
    run check_command "docker"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "docker is available"
}

@test "check_command: error log verification" {
    # Mock 설정
    mock_command_failure
    
    run check_command "missing_tool"
    assert_failure
    assert_output --partial "[ERROR]"
    assert_output --partial "missing_tool is not installed"
}

# =============================================================================
# run_check 테스트들
# =============================================================================

@test "run_check: Docker success" {
    # Mock 설정
    mock_docker_success
    mock_command_success
    
    # 테스트 변수 초기화
    CHECKS_FAILED=0
    
    run run_check "Docker" "docker --version" "20.10.0" "24.0.0"
    assert_success
    assert_output --partial "[CHECK]"
    assert_output --partial "검사 중: Docker"
    assert_output --partial "✅ Docker: 24.0.1"
}

@test "run_check: Docker not installed" {
    # Mock 설정
    mock_command_failure
    
    CHECKS_FAILED=0
    
    run run_check "Docker" "docker --version" "20.10.0" "24.0.0"
    assert_failure
    assert_output --partial "❌ Docker 미설치"
}

@test "run_check: Docker Buildx success" {
    # Mock 설정
    mock_docker_success
    mock_command_success
    
    CHECKS_FAILED=0
    
    run run_check "Docker Buildx" "docker buildx version" "0.10.0" "0.11.0"
    assert_success
    assert_output --partial "✅ Docker Buildx: 0.11.2"
}

@test "run_check: Git success" {
    # Mock 설정
    mock_git_success
    mock_command_success
    
    CHECKS_FAILED=0
    
    run run_check "Git" "git --version" "2.30.0" "2.34.0"
    assert_success
    assert_output --partial "✅ Git: 2.34.1"
}

@test "run_check: unknown command" {
    # Mock 설정
    mock_command_success
    
    CHECKS_FAILED=0
    
    run run_check "Unknown Tool" "unknown --version" "1.0.0" "2.0.0"
    assert_failure
    assert_output --partial "알 수 없는 명령어: unknown --version"
}

@test "run_check: Docker Buildx failure" {
    # Docker는 있지만 Buildx가 없는 경우
    function docker() {
        case "$1" in
            "--version")
                echo "Docker version 24.0.1, build abc123"
                return 0
                ;;
            "buildx")
                echo "docker: 'buildx' is not a docker command" >&2
                return 1
                ;;
        esac
    }
    export -f docker
    
    mock_command_success
    CHECKS_FAILED=0
    
    run run_check "Docker Buildx" "docker buildx version" "0.10.0" "0.11.0"
    assert_failure
}

# =============================================================================
# 고급 테스트들
# =============================================================================

@test "check_command: PATH modification test" {
    # 임시 디렉토리 생성
    local test_dir=$(mktemp -d)
    export PATH="$test_dir:$PATH"
    
    # 가짜 실행 파일 생성
    echo '#!/bin/bash\necho "fake docker"' > "$test_dir/docker"
    chmod +x "$test_dir/docker"
    
    # command -v가 가짜 docker를 찾아야 함
    run bash -c 'command -v docker'
    assert_success
    assert_output --partial "$test_dir/docker"
    
    # check_command도 성공해야 함
    run check_command "docker"
    assert_success
    
    # 정리
    rm -rf "$test_dir"
}

@test "check_command: multiple commands test" {
    # Mock 설정
    mock_command_success
    
    # 여러 명령어를 순차적으로 체크
    run check_command "docker"
    assert_success
    
    run check_command "git"
    assert_success
    
    run check_command "python3"
    assert_success
    
    # 하나는 실패하도록
    mock_missing_tool "nonexistent"
    run check_command "nonexistent"
    assert_failure
    
    # 다시 기존 도구는 성공해야 함
    mock_command_success
    run check_command "docker"
    assert_success
}

# Setup/Teardown
setup() {
    # 전역 변수 초기화
    CHECKS_FAILED=0
}

teardown() {
    # 테스트 변수 정리
    unset CHECKS_FAILED
} 