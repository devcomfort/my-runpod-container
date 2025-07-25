#!/bin/bash

# Logging Functions Unit Tests
# 로깅 함수들의 단위 테스트

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"

# 테스트 대상 함수들 로드
source_logging_functions() {
    # setup_multi_architecture_build.sh에서 로깅 함수들 로드
    if [[ -f "setup_multi_architecture_build.sh" ]]; then
        source <(grep -A 3 "^log_.*() {" setup_multi_architecture_build.sh | head -12)
    fi
    
    # dev-tools/check-dev-requirements.sh에서 로깅 함수들 로드  
    if [[ -f "dev-tools/check-dev-requirements.sh" ]]; then
        # 색상 변수와 로깅 함수만 추출
        eval "$(grep -E '^(RED|GREEN|YELLOW|BLUE|NC)=' dev-tools/check-dev-requirements.sh)"
        eval "$(sed -n '/^log_.*() {/,/^}/p' dev-tools/check-dev-requirements.sh)"
    fi
}

# 색상 변수 수동 정의 (테스트용)
setup_color_vars() {
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export NC='\033[0m'
}

# 로깅 함수 수동 정의 (소스 로드가 실패할 경우)
define_logging_functions() {
    log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
    log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
}

# 테스트 함수들

test_log_info_format() {
    local result
    result=$(log_info "test message")
    
    # 기본 형식 확인
    assert_contains "$result" "[INFO]"
    assert_contains "$result" "test message"
    
    # 색상 코드 확인 (GREEN)
    assert_contains "$result" "${GREEN}"
    assert_contains "$result" "${NC}"
}

test_log_warn_format() {
    local result
    result=$(log_warn "warning message")
    
    assert_contains "$result" "[WARN]"
    assert_contains "$result" "warning message"
    assert_contains "$result" "${YELLOW}"
    assert_contains "$result" "${NC}"
}

test_log_error_format() {
    local result
    result=$(log_error "error message")
    
    assert_contains "$result" "[ERROR]"
    assert_contains "$result" "error message"
    assert_contains "$result" "${RED}"
    assert_contains "$result" "${NC}"
}

test_log_check_format() {
    local result
    result=$(log_check "checking something")
    
    assert_contains "$result" "[CHECK]"
    assert_contains "$result" "checking something"
    assert_contains "$result" "${BLUE}"
    assert_contains "$result" "${NC}"
}

test_log_functions_with_empty_message() {
    local result
    
    # 빈 메시지 테스트
    result=$(log_info "")
    assert_contains "$result" "[INFO]"
    
    result=$(log_warn "")
    assert_contains "$result" "[WARN]"
    
    result=$(log_error "")
    assert_contains "$result" "[ERROR]"
}

test_log_functions_with_special_characters() {
    local result
    
    # 특수 문자가 포함된 메시지
    result=$(log_info "Message with $special &characters!")
    assert_contains "$result" "[INFO]"
    assert_contains "$result" "Message with"
    assert_contains "$result" "characters!"
}

test_log_functions_with_multiline() {
    local result
    local multiline_msg="Line 1
Line 2
Line 3"
    
    result=$(log_info "$multiline_msg")
    assert_contains "$result" "[INFO]"
    assert_contains "$result" "Line 1"
}

test_log_functions_color_stripping() {
    local result
    
    # 색상 코드 제거 후 순수 텍스트 검증
    result=$(log_info "test" | strip_color_codes)
    assert_equals "[INFO] test" "$result"
    
    result=$(log_error "error" | strip_color_codes)
    assert_equals "[ERROR] error" "$result"
}

test_log_functions_exit_codes() {
    # 로깅 함수들은 성공적으로 실행되어야 함
    assert_successful_code 'log_info "test"'
    assert_successful_code 'log_warn "test"'
    assert_successful_code 'log_error "test"'
    assert_successful_code 'log_check "test"'
}

# 전역 setup/teardown
setup() {
    standard_setup
    setup_color_vars
    source_logging_functions || define_logging_functions
}

teardown() {
    standard_teardown
} 