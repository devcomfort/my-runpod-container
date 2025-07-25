#!/bin/bash

# File Operations Unit Tests
# 파일 작업 관련 함수들의 단위 테스트

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"

# execute_script 함수 정의
define_execute_script() {
    execute_script() {
        local script_path=$1
        local script_msg=$2
        if [[ -f ${script_path} ]]; then
            echo "${script_msg}"
            bash ${script_path}
        fi
    }
}

# 기본 execute_script 테스트
test_execute_script_with_valid_file() {
    # 임시 스크립트 생성
    local script_path=$(create_temp_script 'echo "Hello from script"')
    
    # 함수 실행
    local result=$(execute_script "$script_path" "Running test script...")
    
    # 결과 검증
    assert_contains "$result" "Running test script..."
    assert_contains "$result" "Hello from script"
}

# 파일이 없는 경우 테스트
test_execute_script_with_missing_file() {
    local nonexistent_file="$TEST_TMP_DIR/nonexistent.sh"
    
    # 함수 실행 (출력 없어야 함)
    local result=$(execute_script "$nonexistent_file" "Should not appear")
    
    # 메시지가 출력되지 않아야 함
    assert_not_contains "$result" "Should not appear"
    assert_empty "$result"
}

# 실행 권한이 없는 스크립트 테스트
test_execute_script_without_execute_permission() {
    # 실행 권한 없는 스크립트 생성
    local script_path="$TEST_TMP_DIR/no_exec.sh"
    echo '#!/bin/bash\necho "Should not execute"' > "$script_path"
    # 실행 권한 제거
    chmod -x "$script_path"
    
    # 파일은 존재하지만 실행 권한이 없음
    # bash로 직접 실행하므로 여전히 실행될 수 있음
    local result=$(execute_script "$script_path" "Executing...")
    
    assert_contains "$result" "Executing..."
    # bash로 실행하므로 여전히 작동할 수 있음
}

# 빈 스크립트 파일 테스트
test_execute_script_with_empty_file() {
    # 빈 스크립트 파일 생성
    local script_path="$TEST_TMP_DIR/empty.sh"
    touch "$script_path"
    chmod +x "$script_path"
    
    local result=$(execute_script "$script_path" "Running empty script")
    
    # 메시지는 출력되어야 함
    assert_contains "$result" "Running empty script"
}

# 스크립트 실행 실패 테스트
test_execute_script_with_failing_script() {
    # 실패하는 스크립트 생성
    local script_path=$(create_temp_script 'echo "Before error"; exit 1; echo "After error"')
    
    local result=$(execute_script "$script_path" "Running failing script...")
    
    # 메시지와 에러 이전 출력은 나와야 함
    assert_contains "$result" "Running failing script..."
    assert_contains "$result" "Before error"
    assert_not_contains "$result" "After error"
}

# 복잡한 스크립트 테스트
test_execute_script_with_complex_script() {
    # 복잡한 로직이 있는 스크립트
    local script_content='
echo "Starting complex script"
for i in {1..3}; do
    echo "Iteration $i"
done
echo "Complex script completed"
'
    local script_path=$(create_temp_script "$script_content")
    
    local result=$(execute_script "$script_path" "Running complex script...")
    
    assert_contains "$result" "Running complex script..."
    assert_contains "$result" "Starting complex script"
    assert_contains "$result" "Iteration 1"
    assert_contains "$result" "Iteration 2"
    assert_contains "$result" "Iteration 3"
    assert_contains "$result" "Complex script completed"
}

# 환경변수를 사용하는 스크립트 테스트
test_execute_script_with_environment_variables() {
    # 환경변수를 사용하는 스크립트
    local script_content='
echo "TEST_VAR is: $TEST_VAR"
echo "PATH is set: ${PATH:+yes}"
'
    local script_path=$(create_temp_script "$script_content")
    
    # 테스트 환경변수 설정
    export TEST_VAR="test_value"
    
    local result=$(execute_script "$script_path" "Running env script...")
    
    assert_contains "$result" "Running env script..."
    assert_contains "$result" "TEST_VAR is: test_value"
    assert_contains "$result" "PATH is set: yes"
    
    unset TEST_VAR
}

# 인자가 있는 스크립트 테스트 (현재 구현에서는 지원하지 않음)
test_execute_script_current_limitation() {
    # 현재 execute_script는 인자를 전달하지 않음
    local script_content='echo "Args count: $#"; echo "Args: $*"'
    local script_path=$(create_temp_script "$script_content")
    
    local result=$(execute_script "$script_path" "Running args script...")
    
    assert_contains "$result" "Running args script..."
    assert_contains "$result" "Args count: 0"  # 인자가 전달되지 않음
}

# 경로에 공백이 있는 스크립트 테스트
test_execute_script_with_spaces_in_path() {
    # 공백이 있는 디렉토리 생성
    local space_dir="$TEST_TMP_DIR/dir with spaces"
    mkdir -p "$space_dir"
    
    # 공백이 있는 경로에 스크립트 생성
    local script_path="$space_dir/script with spaces.sh"
    echo '#!/bin/bash\necho "Script in spaced path executed"' > "$script_path"
    chmod +x "$script_path"
    
    local result=$(execute_script "$script_path" "Running spaced script...")
    
    assert_contains "$result" "Running spaced script..."
    assert_contains "$result" "Script in spaced path executed"
}

# 상대 경로 스크립트 테스트
test_execute_script_with_relative_path() {
    # 현재 디렉토리에 상대적인 스크립트
    local rel_script="./temp_rel_script.sh"
    echo '#!/bin/bash\necho "Relative path script"' > "$rel_script"
    chmod +x "$rel_script"
    
    local result=$(execute_script "$rel_script" "Running relative script...")
    
    assert_contains "$result" "Running relative script..."
    assert_contains "$result" "Relative path script"
    
    # 정리
    rm -f "$rel_script"
}

# 심볼릭 링크 스크립트 테스트
test_execute_script_with_symlink() {
    # 원본 스크립트 생성
    local original_script=$(create_temp_script 'echo "Original script via symlink"')
    
    # 심볼릭 링크 생성
    local symlink_script="$TEST_TMP_DIR/symlink_script.sh"
    ln -s "$original_script" "$symlink_script"
    
    local result=$(execute_script "$symlink_script" "Running symlinked script...")
    
    assert_contains "$result" "Running symlinked script..."
    assert_contains "$result" "Original script via symlink"
}

# 함수 정의 확인
test_execute_script_function_exists() {
    # 함수가 정의되어 있는지 확인
    assert_true 'function_exists execute_script'
}

# 빈 인자 처리 테스트
test_execute_script_with_empty_arguments() {
    local script_path=$(create_temp_script 'echo "Empty args test"')
    
    # 빈 메시지로 실행
    local result=$(execute_script "$script_path" "")
    
    # 빈 메시지도 출력되어야 함
    assert_contains "$result" "Empty args test"
    # 빈 문자열은 포함되지 않을 수 있음
}

# 전역 setup/teardown
setup() {
    standard_setup
    
    # container/scripts/start.sh에서 실제 함수 로드 시도
    if [[ -f "container/scripts/start.sh" ]]; then
        source <(sed -n '/^execute_script() {/,/^}/p' container/scripts/start.sh) 2>/dev/null || define_execute_script
    else
        define_execute_script
    fi
}

teardown() {
    # 테스트에서 생성한 임시 파일들 정리 (standard_teardown에서 처리됨)
    standard_teardown
} 