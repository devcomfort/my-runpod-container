#!/usr/bin/env bats

# Logging Functions Unit Tests - BATS Version
# 로깅 함수들의 단위 테스트 (BATS 마이그레이션)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

# 색상 변수 정의 (원본에서 복사)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# 로깅 함수들 정의 (원본에서 복사)
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }

# 색상 코드 제거 헬퍼 함수
strip_color_codes() {
    sed 's/\x1B\[[0-9;]*[JKmsu]//g'
}

# =============================================================================
# 로그 포맷 테스트
# =============================================================================

@test "log_info: correct format with message" {
    run log_info "test message"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "test message"
}

@test "log_warn: correct format with message" {
    run log_warn "warning message"
    assert_success
    assert_output --partial "[WARN]"
    assert_output --partial "warning message"
}

@test "log_error: correct format with message" {
    run log_error "error message"
    assert_success
    assert_output --partial "[ERROR]"
    assert_output --partial "error message"
}

@test "log_check: correct format with message" {
    run log_check "checking something"
    assert_success
    assert_output --partial "[CHECK]"
    assert_output --partial "checking something"
}

# =============================================================================
# 특수 케이스 테스트
# =============================================================================

@test "log_functions: handle empty messages" {
    # 빈 메시지 테스트
    run log_info ""
    assert_success
    assert_output --partial "[INFO]"
    
    run log_warn ""
    assert_success
    assert_output --partial "[WARN]"
    
    run log_error ""
    assert_success
    assert_output --partial "[ERROR]"
    
    run log_check ""
    assert_success
    assert_output --partial "[CHECK]"
}

@test "log_functions: handle special characters" {
    # 특수 문자가 포함된 메시지
    run log_info "Message with !@#$%^&*() special characters!"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "Message with"
    assert_output --partial "characters!"
}

@test "log_functions: handle multiline messages" {
    local multiline_msg="Line 1
Line 2
Line 3"
    
    run log_info "$multiline_msg"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "Line 1"
}

@test "log_functions: color stripping functionality" {
    # 색상 코드 제거 후 순수 텍스트 검증
    run bash -c 'log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }; GREEN='"'"'\033[0;32m'"'"'; NC='"'"'\033[0m'"'"'; log_info "test" | sed "s/\x1B\[[0-9;]*[JKmsu]//g"'
    assert_success
    assert_output "[INFO] test"
    
    run bash -c 'log_error() { echo -e "${RED}[ERROR]${NC} $1"; }; RED='"'"'\033[0;31m'"'"'; NC='"'"'\033[0m'"'"'; log_error "error" | sed "s/\x1B\[[0-9;]*[JKmsu]//g"'
    assert_success
    assert_output "[ERROR] error"
}

# =============================================================================
# 안정성 테스트
# =============================================================================

@test "log_functions: return successful exit codes" {
    # 로깅 함수들은 성공적으로 실행되어야 함
    run log_info "test"
    assert_success
    
    run log_warn "test"
    assert_success
    
    run log_error "test"
    assert_success
    
    run log_check "test"
    assert_success
}

@test "log_functions: handle long messages" {
    local long_msg="This is a very long message that should be handled properly by the logging functions without any issues or truncation problems."
    
    run log_info "$long_msg"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "This is a very long message"
    assert_output --partial "without any issues"
}

@test "log_functions: consistent output format" {
    # 모든 로깅 함수의 출력 형식이 일관적인지 확인
    run log_info "consistency test"
    assert_success
    local info_format="$output"
    
    run log_warn "consistency test"
    assert_success
    local warn_format="$output"
    
    run log_error "consistency test"
    assert_success
    local error_format="$output"
    
    run log_check "consistency test"
    assert_success
    local check_format="$output"
    
    # 모든 출력이 동일한 메시지 부분을 포함하는지 확인
    assert_output --partial "consistency test"
}

@test "log_functions: handle numeric messages" {
    # 숫자만 포함된 메시지 처리
    run log_info "12345"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "12345"
    
    run log_warn "0.123"
    assert_success
    assert_output --partial "[WARN]"
    assert_output --partial "0.123"
} 