#!/bin/bash

# Version Compare Function Unit Tests
# 버전 비교 함수의 단위 테스트

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/tests/helpers/test_helpers.sh"

# version_compare 함수 정의
define_version_compare() {
    version_compare() {
        local version1=$1
        local version2=$2
        local operator=$3
        
        # 버전 문자열을 숫자로 변환 (예: 24.0.1 -> 24000100)
        ver1=$(echo "$version1" | sed 's/[^0-9.]//g' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
        ver2=$(echo "$version2" | sed 's/[^0-9.]//g' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
        
        case $operator in
            ">=") [ "$ver1" -ge "$ver2" ];;
            ">") [ "$ver1" -gt "$ver2" ];;
            "=") [ "$ver1" -eq "$ver2" ];;
            *) return 1;;
        esac
    }
}

# 기본 비교 테스트
test_version_compare_basic_greater_than() {
    assert_true 'version_compare "2.1.0" "2.0.0" ">="'
    assert_true 'version_compare "3.0.0" "2.9.9" ">="'
    assert_true 'version_compare "1.2.3" "1.2.2" ">="'
}

test_version_compare_basic_less_than() {
    assert_false 'version_compare "1.9.0" "2.0.0" ">="'
    assert_false 'version_compare "2.0.0" "2.0.1" ">="'
    assert_false 'version_compare "1.9.9" "2.0.0" ">="'
}

test_version_compare_equal() {
    assert_true 'version_compare "2.0.0" "2.0.0" ">="'
    assert_true 'version_compare "1.2.3" "1.2.3" "="'
    assert_true 'version_compare "24.0.1" "24.0.1" "="'
}

test_version_compare_strict_greater() {
    assert_true 'version_compare "2.0.1" "2.0.0" ">"'
    assert_true 'version_compare "3.0.0" "2.9.9" ">"'
    assert_false 'version_compare "2.0.0" "2.0.0" ">"'  # 같으면 false
}

# Docker 버전 관련 실제 케이스
test_version_compare_docker_versions() {
    # Docker 최소 요구사항 테스트
    assert_true 'version_compare "24.0.1" "20.10.0" ">="'
    assert_true 'version_compare "20.10.17" "20.10.0" ">="'
    assert_false 'version_compare "19.03.0" "20.10.0" ">="'
    
    # Buildx 버전 테스트
    assert_true 'version_compare "0.11.2" "0.10.0" ">="'
    assert_true 'version_compare "0.12.0" "0.11.0" ">="'
}

# Git 버전 관련 실제 케이스
test_version_compare_git_versions() {
    assert_true 'version_compare "2.34.1" "2.30.0" ">="'
    assert_true 'version_compare "2.40.0" "2.30.0" ">="'
    assert_false 'version_compare "2.29.0" "2.30.0" ">="'
}

# 엣지 케이스 테스트
test_version_compare_edge_cases() {
    # 단일 숫자 버전
    assert_true 'version_compare "3" "2" ">="'
    assert_true 'version_compare "10" "9" ">="'
    
    # 두 자리 버전
    assert_true 'version_compare "1.2" "1.1" ">="'
    assert_true 'version_compare "2.0" "1.9" ">="'
    
    # 네 자리 버전 (일부는 무시됨)
    assert_true 'version_compare "1.2.3.4" "1.2.3.3" ">="'
}

# 비정상적인 버전 형식 테스트
test_version_compare_with_prefixes() {
    # 'v' 접두사가 있는 버전들
    assert_true 'version_compare "v2.1.0" "v2.0.0" ">="'
    assert_true 'version_compare "version2.1.0" "version2.0.0" ">="'
    
    # 문자가 섞인 버전들 (sed로 숫자만 추출)
    assert_true 'version_compare "2.1.0-beta" "2.0.0-stable" ">="'
    assert_true 'version_compare "2.1.0rc1" "2.0.0" ">="'
}

# 0이 포함된 버전 테스트
test_version_compare_with_zeros() {
    assert_true 'version_compare "1.0.0" "0.9.9" ">="'
    assert_true 'version_compare "2.0.1" "2.0.0" ">="'
    assert_true 'version_compare "1.1.0" "1.0.9" ">="'
    
    # 0으로 시작하는 버전
    assert_false 'version_compare "0.9.0" "1.0.0" ">="'
    assert_true 'version_compare "0.10.0" "0.9.0" ">="'
}

# 큰 숫자 버전 테스트
test_version_compare_large_numbers() {
    assert_true 'version_compare "24.0.1" "23.9.9" ">="'
    assert_true 'version_compare "100.0.0" "99.99.99" ">="'
    assert_false 'version_compare "99.0.0" "100.0.0" ">="'
}

# 잘못된 연산자 테스트
test_version_compare_invalid_operator() {
    # 잘못된 연산자는 false를 반환해야 함
    assert_false 'version_compare "2.0.0" "1.0.0" "<"'
    assert_false 'version_compare "2.0.0" "1.0.0" "=="'
    assert_false 'version_compare "2.0.0" "1.0.0" "invalid"'
}

# 빈 문자열 및 NULL 처리
test_version_compare_empty_versions() {
    # 빈 버전 문자열 (결과는 정의되지 않음, 하지만 크래시는 안 해야 함)
    assert_exit_code 1 'version_compare "" "1.0.0" ">="'
    assert_exit_code 1 'version_compare "1.0.0" "" ">="'
}

# 정확한 숫자 변환 검증
test_version_number_conversion() {
    # 내부적으로 사용되는 숫자 변환이 올바른지 확인
    # 24.0.1 -> 24000001, 20.10.0 -> 20010000
    assert_true 'version_compare "24.0.1" "20.10.0" ">="'
    
    # 0.11.2 -> 000011002, 0.10.0 -> 000010000  
    assert_true 'version_compare "0.11.2" "0.10.0" ">="'
}

# 성능 테스트 (함수가 빠르게 실행되는지)
test_version_compare_performance() {
    # 100번 실행해도 빠르게 완료되어야 함
    local start_time=$(date +%s%N)
    for i in {1..100}; do
        version_compare "2.1.0" "2.0.0" ">=" >/dev/null
    done
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    local duration_ms=$((duration / 1000000))
    
    # 100번 실행이 1초(1000ms) 미만이어야 함
    assert_true "[ $duration_ms -lt 1000 ]"
}

# 전역 setup/teardown
setup() {
    standard_setup
    
    # dev-tools/check-dev-requirements.sh에서 실제 함수 로드 시도
    if [[ -f "dev-tools/check-dev-requirements.sh" ]]; then
        source <(sed -n '/^version_compare() {/,/^}/p' dev-tools/check-dev-requirements.sh) 2>/dev/null || {
            define_version_compare
        }
    else
        define_version_compare
    fi
}

teardown() {
    standard_teardown
} 