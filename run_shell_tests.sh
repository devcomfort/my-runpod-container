#!/bin/bash

# Shell Tests Runner
# 모든 shell 테스트를 실행하는 메인 스크립트

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
log_header() { echo -e "${BLUE}[TEST]${NC} $1"; }

# 기본 설정
BASHUNIT_PATH="./lib/bashunit"
TEST_DIR="./tests"
VERBOSE=${VERBOSE:-false}
RUN_INTEGRATION=${RUN_INTEGRATION:-false}
RUN_ONLY=""

# 사용법 출력
show_usage() {
    cat << EOF
Shell Tests Runner

사용법: $0 [OPTIONS] [TEST_PATTERN]

OPTIONS:
    -h, --help              이 도움말 표시
    -v, --verbose           자세한 출력
    -i, --integration       통합 테스트 포함 실행
    -u, --unit-only         단위 테스트만 실행
    -m, --mocked-only       모킹 테스트만 실행
    --version               bashunit 버전 표시

TEST_PATTERN:
    특정 테스트 파일이나 패턴 지정 (예: version_compare)

예시:
    $0                      # 모든 단위 및 모킹 테스트 실행
    $0 -i                   # 통합 테스트 포함 모든 테스트 실행
    $0 -u                   # 단위 테스트만 실행
    $0 version_compare      # version_compare 관련 테스트만 실행
    $0 -v logging           # 로깅 관련 테스트를 자세한 출력으로 실행

환경변수:
    VERBOSE=true            자세한 출력 활성화
    RUN_INTEGRATION=true    통합 테스트 포함
    FORCE_INTEGRATION=true  Docker 통합 테스트 강제 실행
EOF
}

# bashunit 존재 확인
check_bashunit() {
    if [[ ! -f "$BASHUNIT_PATH" ]]; then
        log_error "bashunit을 찾을 수 없습니다: $BASHUNIT_PATH"
        log_info "bashunit 설치 방법:"
        log_info "  curl -s https://bashunit.typeddevs.com/install.sh | bash"
        exit 1
    fi
    
    if [[ ! -x "$BASHUNIT_PATH" ]]; then
        log_warn "bashunit에 실행 권한이 없습니다. 권한을 설정합니다..."
        chmod +x "$BASHUNIT_PATH"
    fi
}

# 테스트 디렉토리 확인
check_test_directories() {
    if [[ ! -d "$TEST_DIR" ]]; then
        log_error "테스트 디렉토리를 찾을 수 없습니다: $TEST_DIR"
        exit 1
    fi
    
    local required_dirs=("unit" "unit_mocked" "helpers")
    local optional_dirs=("integration")
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$TEST_DIR/$dir" ]]; then
            log_error "필수 테스트 디렉토리가 없습니다: $TEST_DIR/$dir"
            exit 1
        fi
    done
    
    for dir in "${optional_dirs[@]}"; do
        if [[ ! -d "$TEST_DIR/$dir" ]]; then
            log_warn "선택적 테스트 디렉토리가 없습니다: $TEST_DIR/$dir"
        fi
    done
}

# 테스트 파일 목록 수집
collect_test_files() {
    local pattern="$1"
    local include_integration="$2"
    local files=()
    
    # 단위 테스트
    if [[ "$RUN_ONLY" == "" || "$RUN_ONLY" == "unit" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -z "$pattern" || "$file" =~ $pattern ]]; then
                files+=("$file")
            fi
        done < <(find "$TEST_DIR/unit" -name "*test.sh" -type f -print0 2>/dev/null)
    fi
    
    # 모킹 테스트
    if [[ "$RUN_ONLY" == "" || "$RUN_ONLY" == "mocked" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -z "$pattern" || "$file" =~ $pattern ]]; then
                files+=("$file")
            fi
        done < <(find "$TEST_DIR/unit_mocked" -name "*test.sh" -type f -print0 2>/dev/null)
    fi
    
    # 통합 테스트 (선택적)
    if [[ "$include_integration" == "true" && -d "$TEST_DIR/integration" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -z "$pattern" || "$file" =~ $pattern ]]; then
                files+=("$file")
            fi
        done < <(find "$TEST_DIR/integration" -name "*test.sh" -type f -print0 2>/dev/null)
    fi
    
    printf '%s\n' "${files[@]}"
}

# 개별 테스트 파일 실행
run_single_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    log_header "실행 중: $test_name"
    
    local cmd="$BASHUNIT_PATH $test_file"
    if [[ "$VERBOSE" == "true" ]]; then
        cmd="$cmd --verbose"
    fi
    
    if $cmd; then
        log_info "✅ $test_name 통과"
        return 0
    else
        log_error "❌ $test_name 실패"
        return 1
    fi
}

# 테스트 실행 요약
run_test_summary() {
    local total_tests="$1"
    local passed_tests="$2"
    local failed_tests="$3"
    
    echo ""
    echo "=================================="
    log_header "테스트 실행 요약"
    echo "=================================="
    echo "총 테스트 파일: $total_tests"
    echo "통과: $passed_tests"
    echo "실패: $failed_tests"
    
    if [[ $failed_tests -eq 0 ]]; then
        log_info "🎉 모든 테스트가 통과했습니다!"
        return 0
    else
        log_error "💥 $failed_tests개의 테스트가 실패했습니다."
        return 1
    fi
}

# 시스템 정보 출력
show_system_info() {
    echo "🔍 시스템 정보:"
    echo "  • OS: $(uname -s) $(uname -m)"
    echo "  • Bash: $BASH_VERSION"
    echo "  • Bashunit: $($BASHUNIT_PATH --version 2>/dev/null || echo 'Unknown')"
    echo "  • 작업 디렉토리: $(pwd)"
    echo "  • 테스트 디렉토리: $TEST_DIR"
    
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version 2>/dev/null || echo "Docker not available")
        echo "  • Docker: $docker_version"
    fi
    
    echo ""
}

# 메인 실행 함수
main() {
    local pattern=""
    
    # 명령행 인자 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -i|--integration)
                RUN_INTEGRATION=true
                shift
                ;;
            -u|--unit-only)
                RUN_ONLY="unit"
                shift
                ;;
            -m|--mocked-only)
                RUN_ONLY="mocked"
                shift
                ;;
            --version)
                echo "Shell Tests Runner v1.0.0"
                $BASHUNIT_PATH --version 2>/dev/null || echo "bashunit: Unknown version"
                exit 0
                ;;
            -*)
                log_error "알 수 없는 옵션: $1"
                show_usage
                exit 1
                ;;
            *)
                pattern="$1"
                shift
                ;;
        esac
    done
    
    # 초기 검사
    check_bashunit
    check_test_directories
    
    # 시스템 정보 출력
    if [[ "$VERBOSE" == "true" ]]; then
        show_system_info
    fi
    
    # 테스트 파일 수집
    log_info "테스트 파일을 수집하는 중..."
    local test_files
    mapfile -t test_files < <(collect_test_files "$pattern" "$RUN_INTEGRATION")
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_warn "실행할 테스트 파일이 없습니다."
        if [[ -n "$pattern" ]]; then
            log_info "패턴 '$pattern'과 일치하는 테스트를 찾을 수 없습니다."
        fi
        exit 0
    fi
    
    log_info "총 ${#test_files[@]}개의 테스트 파일을 발견했습니다."
    
    # 통합 테스트 경고
    if [[ "$RUN_INTEGRATION" == "true" ]]; then
        log_warn "통합 테스트가 포함됩니다. Docker daemon이 필요할 수 있습니다."
        echo "  • Docker 통합 테스트를 강제로 실행하려면: FORCE_INTEGRATION=true"
        echo ""
    fi
    
    # 테스트 실행
    local passed=0
    local failed=0
    
    for test_file in "${test_files[@]}"; do
        if run_single_test "$test_file"; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # 결과 요약
    run_test_summary "${#test_files[@]}" "$passed" "$failed"
}

# 스크립트 실행
main "$@" 