#!/usr/bin/env bats

# Version Compare Function Unit Tests - BATS Version
# 버전 비교 함수의 단위 테스트 (BATS 마이그레이션)

# BATS 헬퍼 라이브러리 로드
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

# version_compare 함수 정의 (원본에서 직접 복사)
version_compare() {
    local version1=$1
    local version2=$2
    local operator=$3
    
    # 빈 문자열 체크 추가 (bootstrap.sh의 개선사항 반영)
    if [[ -z "$version1" || -z "$version2" ]]; then
        return 1
    fi
    
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

# =============================================================================
# 기본 비교 테스트
# =============================================================================

@test "version_compare: basic greater than comparisons" {
    run version_compare "2.1.0" "2.0.0" ">="
    assert_success
    
    run version_compare "3.0.0" "2.9.9" ">="
    assert_success
    
    run version_compare "1.2.3" "1.2.2" ">="
    assert_success
}

@test "version_compare: basic less than comparisons" {
    run version_compare "1.9.0" "2.0.0" ">="
    assert_failure
    
    run version_compare "2.0.0" "2.0.1" ">="
    assert_failure
    
    run version_compare "1.9.9" "2.0.0" ">="
    assert_failure
}

@test "version_compare: equal versions" {
    run version_compare "2.0.0" "2.0.0" ">="
    assert_success
    
    run version_compare "1.2.3" "1.2.3" "="
    assert_success
    
    run version_compare "24.0.1" "24.0.1" "="
    assert_success
}

@test "version_compare: strict greater than comparisons" {
    run version_compare "2.0.1" "2.0.0" ">"
    assert_success
    
    run version_compare "3.0.0" "2.9.9" ">"
    assert_success
    
    # 같으면 false
    run version_compare "2.0.0" "2.0.0" ">"
    assert_failure
}

# =============================================================================
# 실제 사용 케이스 테스트
# =============================================================================

@test "version_compare: Docker version requirements" {
    # Docker 최소 요구사항 테스트
    run version_compare "24.0.1" "20.10.0" ">="
    assert_success
    
    run version_compare "20.10.17" "20.10.0" ">="
    assert_success
    
    run version_compare "19.03.0" "20.10.0" ">="
    assert_failure
    
    # Buildx 버전 테스트
    run version_compare "0.11.2" "0.10.0" ">="
    assert_success
    
    run version_compare "0.12.0" "0.11.0" ">="
    assert_success
}

@test "version_compare: Git version requirements" {
    run version_compare "2.34.1" "2.30.0" ">="
    assert_success
    
    run version_compare "2.40.0" "2.30.0" ">="
    assert_success
    
    run version_compare "2.29.0" "2.30.0" ">="
    assert_failure
}

# =============================================================================
# 엣지 케이스 테스트
# =============================================================================

@test "version_compare: edge cases with different version formats" {
    # 단일 숫자 버전
    run version_compare "3" "2" ">="
    assert_success
    
    run version_compare "10" "9" ">="
    assert_success
    
    # 두 자리 버전
    run version_compare "1.2" "1.1" ">="
    assert_success
    
    run version_compare "2.0" "1.9" ">="
    assert_success
    
    # 네 자리 버전 (일부는 무시됨)
    run version_compare "1.2.3.4" "1.2.3.3" ">="
    assert_success
}

@test "version_compare: versions with prefixes and suffixes" {
    # 'v' 접두사가 있는 버전들
    run version_compare "v2.1.0" "v2.0.0" ">="
    assert_success
    
    run version_compare "version2.1.0" "version2.0.0" ">="
    assert_success
    
    # 문자가 섞인 버전들 (sed로 숫자만 추출)
    run version_compare "2.1.0-beta" "2.0.0-stable" ">="
    assert_success
    
    run version_compare "2.1.0rc1" "2.0.0" ">="
    assert_success
}

@test "version_compare: versions with zeros" {
    run version_compare "1.0.0" "0.9.9" ">="
    assert_success
    
    run version_compare "2.0.1" "2.0.0" ">="
    assert_success
    
    run version_compare "1.1.0" "1.0.9" ">="
    assert_success
    
    # 0으로 시작하는 버전
    run version_compare "0.9.0" "1.0.0" ">="
    assert_failure
    
    run version_compare "0.10.0" "0.9.0" ">="
    assert_success
}

@test "version_compare: large version numbers" {
    run version_compare "24.0.1" "23.9.9" ">="
    assert_success
    
    run version_compare "100.0.0" "99.99.99" ">="
    assert_success
    
    run version_compare "99.0.0" "100.0.0" ">="
    assert_failure
}

# =============================================================================
# 에러 케이스 테스트
# =============================================================================

@test "version_compare: invalid operators" {
    # 잘못된 연산자는 false를 반환해야 함
    run version_compare "2.0.0" "1.0.0" "<"
    assert_failure
    
    run version_compare "2.0.0" "1.0.0" "=="
    assert_failure
    
    run version_compare "2.0.0" "1.0.0" "invalid"
    assert_failure
}

@test "version_compare: empty version strings" {
    # 빈 버전 문자열 처리 테스트
    run version_compare "" "1.0.0" ">="
    assert_failure
    
    run version_compare "1.0.0" "" ">="
    assert_failure
    
    run version_compare "" "" ">="
    assert_failure
}

@test "version_compare: number conversion accuracy" {
    # 숫자 변환이 올바른지 확인
    run version_compare "2.1.0" "2.0.0" ">="
    assert_success
    
    run version_compare "1.10.0" "1.9.0" ">="
    assert_success
    
    run version_compare "1.0.10" "1.0.9" ">="
    assert_success
}

@test "version_compare: performance with multiple calls" {
    # 기본 성능 확인 - 여러 번 호출해도 정상 작동
    for i in {1..10}; do
        run version_compare "1.0.0" "0.9.0" ">="
        assert_success
    done
} 