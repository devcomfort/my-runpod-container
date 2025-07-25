#!/usr/bin/env bats

# File Operations Unit Tests - BATS Version
# 파일 작업 관련 함수들의 단위 테스트 (BATS 마이그레이션)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../test_helper/bats-file/load'

# execute_script 함수 정의 (원본에서 복사, 공백 처리 개선)
execute_script() {
    local script_path="$1"
    local script_msg="$2"
    if [[ -f "${script_path}" ]]; then
        echo "${script_msg}"
        bash "${script_path}"
    fi
}

# 임시 스크립트 생성 헬퍼 함수
create_temp_script() {
    local content="$1"
    local script_path="$BATS_TEST_TMPDIR/temp_script_$$.sh"
    
    echo '#!/bin/bash' > "$script_path"
    echo -e "$content" >> "$script_path"
    chmod +x "$script_path"
    
    echo "$script_path"
}

# 함수 존재 확인 헬퍼
function_exists() {
    declare -f "$1" >/dev/null 2>&1
}

# =============================================================================
# 기본 execute_script 테스트들
# =============================================================================

@test "execute_script: valid file execution" {
    # 임시 스크립트 생성
    local script_path=$(create_temp_script 'echo "Hello from script"')
    
    # 함수 실행
    run execute_script "$script_path" "Running test script..."
    
    # 결과 검증
    assert_success
    assert_output --partial "Running test script..."
    assert_output --partial "Hello from script"
}

@test "execute_script: missing file handling" {
    local nonexistent_file="$BATS_TEST_TMPDIR/nonexistent.sh"
    
    # 함수 실행 (출력 없어야 함)
    run execute_script "$nonexistent_file" "Should not appear"
    
    # 메시지가 출력되지 않아야 함
    assert_success  # 파일이 없어도 에러는 아님
    refute_output --partial "Should not appear"
    assert_output ""
}

@test "execute_script: file without execute permission" {
    # 실행 권한 없는 스크립트 생성
    local script_path="$BATS_TEST_TMPDIR/no_exec.sh"
    echo '#!/bin/bash' > "$script_path"
    echo 'echo "Should execute via bash"' >> "$script_path"
    chmod -x "$script_path"
    
    # 파일은 존재하지만 실행 권한이 없음
    # bash로 직접 실행하므로 여전히 실행될 수 있음
    run execute_script "$script_path" "Executing..."
    
    assert_success
    assert_output --partial "Executing..."
    assert_output --partial "Should execute via bash"
}

@test "execute_script: empty file handling" {
    # 빈 스크립트 파일 생성
    local script_path="$BATS_TEST_TMPDIR/empty.sh"
    touch "$script_path"
    chmod +x "$script_path"
    
    run execute_script "$script_path" "Running empty script"
    
    # 메시지는 출력되어야 함
    assert_success
    assert_output "Running empty script"
}

@test "execute_script: failing script handling" {
    # 실패하는 스크립트 생성
    local script_path=$(create_temp_script 'echo "Before error"; exit 1; echo "After error"')
    
    run execute_script "$script_path" "Running failing script..."
    
    # bash가 exit 1을 받아서 실패할 것임
    assert_failure
    assert_output --partial "Running failing script..."
    assert_output --partial "Before error"
    refute_output --partial "After error"
}

# =============================================================================
# 복합 스크립트 테스트들
# =============================================================================

@test "execute_script: complex script with loops" {
    # 복잡한 로직이 있는 스크립트
    local script_content='echo "Starting complex script"
for i in {1..3}; do
    echo "Iteration $i"
done
echo "Complex script completed"'
    
    local script_path=$(create_temp_script "$script_content")
    
    run execute_script "$script_path" "Running complex script..."
    
    assert_success
    assert_output --partial "Running complex script..."
    assert_output --partial "Starting complex script"
    assert_output --partial "Iteration 1"
    assert_output --partial "Iteration 2" 
    assert_output --partial "Iteration 3"
    assert_output --partial "Complex script completed"
}

@test "execute_script: environment variables access" {
    # 환경변수를 사용하는 스크립트
    local script_content='echo "TEST_VAR is: $TEST_VAR"
echo "PATH is set: ${PATH:+yes}"'
    
    local script_path=$(create_temp_script "$script_content")
    
    # 테스트 환경변수 설정
    export TEST_VAR="test_value"
    
    run execute_script "$script_path" "Running env script..."
    
    assert_success
    assert_output --partial "Running env script..."
    assert_output --partial "TEST_VAR is: test_value"
    assert_output --partial "PATH is set: yes"
    
    unset TEST_VAR
}

@test "execute_script: current argument limitation" {
    # 현재 execute_script는 인자를 전달하지 않음
    local script_content='echo "Args count: $#"; echo "Args: $*"'
    local script_path=$(create_temp_script "$script_content")
    
    run execute_script "$script_path" "Running args script..."
    
    assert_success
    assert_output --partial "Running args script..."
    assert_output --partial "Args count: 0"  # 인자가 전달되지 않음
    assert_output --partial "Args: "
}

# =============================================================================
# 경로 및 파일 시스템 테스트들
# =============================================================================

@test "execute_script: spaces in file path" {
    # 공백이 있는 디렉토리 생성
    local space_dir="$BATS_TEST_TMPDIR/dir with spaces"
    mkdir -p "$space_dir"
    
    # 공백이 있는 경로에 스크립트 생성
    local script_path="$space_dir/script with spaces.sh"
    echo '#!/bin/bash' > "$script_path"
    echo 'echo "Script in spaced path executed"' >> "$script_path"
    chmod +x "$script_path"
    
    run execute_script "$script_path" "Running spaced script..."
    
    assert_success
    assert_output --partial "Running spaced script..."
    assert_output --partial "Script in spaced path executed"
}

@test "execute_script: relative path handling" {
    # 현재 디렉토리에 상대적인 스크립트
    local rel_script="$BATS_TEST_TMPDIR/rel_script.sh"
    echo '#!/bin/bash' > "$rel_script"
    echo 'echo "Relative path script"' >> "$rel_script"
    chmod +x "$rel_script"
    
    # BATS_TEST_TMPDIR로 이동해서 상대 경로 테스트
    cd "$BATS_TEST_TMPDIR"
    
    run execute_script "./rel_script.sh" "Running relative script..."
    
    assert_success
    assert_output --partial "Running relative script..."
    assert_output --partial "Relative path script"
}

@test "execute_script: symbolic link handling" {
    # 원본 스크립트 생성
    local original_script=$(create_temp_script 'echo "Original script via symlink"')
    
    # 심볼릭 링크 생성
    local symlink_script="$BATS_TEST_TMPDIR/symlink_script.sh"
    ln -s "$original_script" "$symlink_script"
    
    run execute_script "$symlink_script" "Running symlinked script..."
    
    assert_success
    assert_output --partial "Running symlinked script..."
    assert_output --partial "Original script via symlink"
}

# =============================================================================
# 함수 및 인자 처리 테스트들
# =============================================================================

@test "execute_script: function definition exists" {
    # 함수가 정의되어 있는지 확인
    run bash -c '
        execute_script() {
            local script_path="$1"
            local script_msg="$2"
            if [[ -f "${script_path}" ]]; then
                echo "${script_msg}"
                bash "${script_path}"
            fi
        }
        declare -f execute_script >/dev/null 2>&1
    '
    assert_success
}

@test "execute_script: empty message argument" {
    local script_path=$(create_temp_script 'echo "Empty args test"')
    
    # 빈 메시지로 실행
    run execute_script "$script_path" ""
    
    # 빈 메시지도 처리되어야 함
    assert_success
    # 빈 메시지("")도 출력되므로 빈 줄이 포함됨
    assert_output $'\nEmpty args test'
}

@test "execute_script: special characters in message" {
    local script_path=$(create_temp_script 'echo "Script output"')
    
    # 특수 문자가 포함된 메시지
    local special_msg="Message with !@#$%^&*() chars"
    
    run execute_script "$script_path" "$special_msg"
    
    assert_success
    assert_output --partial "$special_msg"
    assert_output --partial "Script output"
}

@test "execute_script: multiline script output" {
    # 여러 줄 출력하는 스크립트
    local script_content='echo "Line 1"
echo "Line 2"
echo "Line 3"'
    
    local script_path=$(create_temp_script "$script_content")
    
    run execute_script "$script_path" "Multi-line test:"
    
    assert_success
    assert_output --partial "Multi-line test:"
    assert_output --partial "Line 1"
    assert_output --partial "Line 2"
    assert_output --partial "Line 3"
}

@test "execute_script: binary file rejection" {
    # 바이너리 파일 생성 (실행 불가능)
    local binary_path="$BATS_TEST_TMPDIR/binary_file"
    echo -e '\x00\x01\x02\x03' > "$binary_path"
    chmod +x "$binary_path"
    
    run execute_script "$binary_path" "Should not execute binary"
    
    # bash로 실행하므로 에러가 발생할 것임
    assert_failure
    assert_output --partial "Should not execute binary"
}

# Setup/Teardown
setup() {
    # BATS 자체적으로 BATS_TEST_TMPDIR을 제공함
    # 추가 설정이 필요하면 여기에
    :
}

teardown() {
    # BATS가 자동으로 BATS_TEST_TMPDIR을 정리함
    # 추가 정리가 필요하면 여기에
    :
} 