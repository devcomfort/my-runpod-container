#!/bin/bash

# Test Helper Functions
# 공통으로 사용되는 테스트 유틸리티 함수들

# 테스트 환경 설정
setup_test_env() {
    # 임시 디렉토리 생성
    export TEST_TMP_DIR=$(mktemp -d)
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_PWD="$PWD"
    
    # 테스트용 환경변수 백업
    export ORIG_CI="${CI:-}"
    export ORIG_GITHUB_ACTIONS="${GITHUB_ACTIONS:-}"
    export ORIG_RUNPOD_POD_ID="${RUNPOD_POD_ID:-}"
}

# 테스트 환경 정리
teardown_test_env() {
    # 임시 디렉토리 정리
    if [[ -n "${TEST_TMP_DIR:-}" && -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
    
    # PATH 복원
    export PATH="$ORIGINAL_PATH"
    cd "$ORIGINAL_PWD" 2>/dev/null || true
    
    # 환경변수 복원
    export CI="$ORIG_CI"
    export GITHUB_ACTIONS="$ORIG_GITHUB_ACTIONS"
    export RUNPOD_POD_ID="$ORIG_RUNPOD_POD_ID"
    
    # 모킹된 함수들 정리
    cleanup_mocked_functions
}

# 모킹된 함수 정리
cleanup_mocked_functions() {
    # 주요 명령어들 unset
    local commands_to_unset=(
        "docker" "git" "command" "uname" "service"
        "ssh-keygen" "jupyter" "nginx" "chmod" "mkdir"
    )
    
    for cmd in "${commands_to_unset[@]}"; do
        if declare -F "$cmd" >/dev/null 2>&1; then
            unset -f "$cmd"
        fi
    done
}

# 임시 스크립트 파일 생성
create_temp_script() {
    local script_content="$1"
    local script_path="$TEST_TMP_DIR/temp_script.sh"
    
    echo "#!/bin/bash" > "$script_path"
    echo "$script_content" >> "$script_path"
    chmod +x "$script_path"
    
    echo "$script_path"
}

# 로그 출력에서 색상 코드 제거
strip_color_codes() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# 함수가 정의되어 있는지 확인
function_exists() {
    declare -F "$1" >/dev/null 2>&1
}

# 파일 내용을 변수로 캡처
capture_file_content() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        cat "$file_path"
    fi
}

# 환경변수 모킹
mock_env_var() {
    local var_name="$1"
    local var_value="$2"
    export "$var_name"="$var_value"
}

# 여러 환경변수 한번에 모킹
mock_env_vars() {
    while [[ $# -gt 0 ]]; do
        local var_assignment="$1"
        local var_name="${var_assignment%=*}"
        local var_value="${var_assignment#*=}"
        export "$var_name"="$var_value"
        shift
    done
}

# 테스트 실행 전 표준 setup
standard_setup() {
    setup_test_env
    # 스크립트별 색상 변수들 설정
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export NC='\033[0m'
}

# 테스트 실행 후 표준 teardown  
standard_teardown() {
    teardown_test_env
} 