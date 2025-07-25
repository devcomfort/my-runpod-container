#!/bin/bash

# Command Checks Unit Tests (with Mocking)
# 모킹을 사용한 명령어 체크 함수들의 테스트

# 테스트 헬퍼 및 모킹 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"
source "$PROJECT_ROOT/tests/helpers/mock_commands.sh"

# check_command 함수 정의 (setup_multi_architecture_build.sh에서)
define_check_command() {
    check_command() {
        local cmd="$1"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd is not installed. Please install it first."
            return 1
        fi
        log_info "$cmd is available"
        return 0
    }
}

# run_check 함수 정의 (dev-tools/check-dev-requirements.sh에서)
define_run_check() {
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
}

# check_command 테스트 - 성공 케이스
test_check_command_success() {
    mock_command_success
    
    # Docker 체크
    assert_successful_code 'check_command "docker"'
    
    # Git 체크
    assert_successful_code 'check_command "git"'
    
    # Python 체크
    assert_successful_code 'check_command "python3"'
}

# check_command 테스트 - 실패 케이스
test_check_command_failure() {
    mock_command_failure
    
    # 존재하지 않는 명령어
    assert_exit_code 1 'check_command "nonexistent_tool"'
    assert_exit_code 1 'check_command "docker"'
}

# check_command 테스트 - 특정 도구만 없는 경우
test_check_command_missing_specific_tool() {
    mock_missing_tool "docker"
    
    # Docker는 없고 다른 도구는 있음
    assert_exit_code 1 'check_command "docker"'
    assert_successful_code 'check_command "git"'
}

# check_command 테스트 - 로그 출력 확인
test_check_command_log_output() {
    mock_command_success
    
    local result
    result=$(check_command "docker" 2>&1)
    
    # 성공 로그 메시지 확인
    assert_contains "$result" "[INFO]"
    assert_contains "$result" "docker is available"
}

test_check_command_error_log() {
    mock_command_failure
    
    local result
    result=$(check_command "missing_tool" 2>&1)
    
    # 에러 로그 메시지 확인
    assert_contains "$result" "[ERROR]"
    assert_contains "$result" "missing_tool is not installed"
}

# run_check 테스트 - Docker 성공
test_run_check_docker_success() {
    mock_docker_success
    mock_command_success
    
    # 테스트 변수 초기화
    CHECKS_FAILED=0
    
    local result
    result=$(run_check "Docker" "docker --version" "20.10.0" "24.0.0" 2>&1)
    
    # 성공적으로 실행되어야 함
    assert_equals "0" "$?"
    assert_contains "$result" "[CHECK]"
    assert_contains "$result" "검사 중: Docker"
    assert_contains "$result" "✅ Docker: 24.0.1"
}

# run_check 테스트 - Docker 실패 (미설치)
test_run_check_docker_not_installed() {
    mock_command_failure
    
    CHECKS_FAILED=0
    
    local result
    result=$(run_check "Docker" "docker --version" "20.10.0" "24.0.0" 2>&1)
    
    # 실패해야 함
    assert_exit_code 1 'run_check "Docker" "docker --version" "20.10.0" "24.0.0"'
    assert_equals "1" "$CHECKS_FAILED"
}

# run_check 테스트 - Docker Buildx
test_run_check_docker_buildx() {
    mock_docker_success
    mock_command_success
    
    CHECKS_FAILED=0
    
    local result
    result=$(run_check "Docker Buildx" "docker buildx version" "0.10.0" "0.11.0" 2>&1)
    
    assert_successful_code 'run_check "Docker Buildx" "docker buildx version" "0.10.0" "0.11.0"'
    assert_contains "$result" "✅ Docker Buildx: 0.11.2"
}

# run_check 테스트 - Git
test_run_check_git() {
    mock_git_success
    mock_command_success
    
    CHECKS_FAILED=0
    
    local result
    result=$(run_check "Git" "git --version" "2.30.0" "2.34.0" 2>&1)
    
    assert_successful_code 'run_check "Git" "git --version" "2.30.0" "2.34.0"'
    assert_contains "$result" "✅ Git: 2.34.1"
}

# run_check 테스트 - 알 수 없는 명령어
test_run_check_unknown_command() {
    mock_command_success
    
    CHECKS_FAILED=0
    
    local result
    result=$(run_check "Unknown Tool" "unknown --version" "1.0.0" "2.0.0" 2>&1)
    
    assert_exit_code 1 'run_check "Unknown Tool" "unknown --version" "1.0.0" "2.0.0"'
    assert_contains "$result" "알 수 없는 명령어: unknown --version"
    assert_equals "1" "$CHECKS_FAILED"
}

# run_check 테스트 - Docker Buildx 실패
test_run_check_buildx_failure() {
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
    
    assert_exit_code 1 'run_check "Docker Buildx" "docker buildx version" "0.10.0" "0.11.0"'
    assert_equals "1" "$CHECKS_FAILED"
}

# 환경변수 영향 테스트
test_check_command_with_path_modification() {
    # PATH에 가짜 디렉토리 추가
    export PATH="$TEST_TMP_DIR/fake_bin:$PATH"
    
    # 가짜 실행 파일 생성
    mkdir -p "$TEST_TMP_DIR/fake_bin"
    echo '#!/bin/bash\necho "fake docker"' > "$TEST_TMP_DIR/fake_bin/docker"
    chmod +x "$TEST_TMP_DIR/fake_bin/docker"
    
    # command -v가 가짜 docker를 찾아야 함
    local docker_path
    docker_path=$(command -v docker)
    assert_contains "$docker_path" "fake_bin/docker"
    
    # check_command도 성공해야 함
    assert_successful_code 'check_command "docker"'
}

# 동시성 테스트 (여러 명령어 체크)
test_check_multiple_commands() {
    mock_command_success
    
    # 여러 명령어를 순차적으로 체크
    assert_successful_code 'check_command "docker"'
    assert_successful_code 'check_command "git"'
    assert_successful_code 'check_command "python3"'
    
    # 하나는 실패하도록
    mock_missing_tool "nonexistent"
    assert_exit_code 1 'check_command "nonexistent"'
    
    # 다시 기존 도구는 성공해야 함
    mock_command_success
    assert_successful_code 'check_command "docker"'
}

# 전역 setup/teardown
setup() {
    standard_setup
    
    # 로깅 함수들도 필요함
    log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
    log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
    
    # 테스트할 함수들 정의
    define_check_command
    define_run_check
    
    # 전역 변수 초기화
    CHECKS_FAILED=0
}

teardown() {
    # 테스트 변수 정리
    unset CHECKS_FAILED
    
    standard_teardown
} 