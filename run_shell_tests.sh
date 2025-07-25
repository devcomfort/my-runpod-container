#!/bin/bash

# Shell Tests Runner - BATS Edition
# BATS 기반 shell 테스트를 실행하는 메인 스크립트

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
BATS_PATH="./node_modules/.bin/bats"
TEST_DIR="./tests/bats"
VERBOSE=${VERBOSE:-false}
RUN_INTEGRATION=${RUN_INTEGRATION:-false}
PARALLEL=${PARALLEL:-false}
JOBS=${JOBS:-4}
FORMAT=${FORMAT:-"pretty"}

# 사용법 출력
show_usage() {
    cat << EOF
Shell Tests Runner - BATS Edition

사용법: $0 [OPTIONS] [TEST_PATTERN]

OPTIONS:
    -h, --help              이 도움말 표시
    -v, --verbose           자세한 출력
    -i, --integration       통합 테스트 포함 실행 (Docker 필요)
    -p, --parallel          병렬 테스트 실행 (기본: 4 jobs)
    -j, --jobs NUMBER       병렬 실행 시 job 수 지정
    -f, --format FORMAT     출력 형식 (pretty|tap|junit)
    --list                  사용 가능한 테스트 파일 목록
    --version               BATS 버전 표시

TEST_PATTERN:
    특정 테스트 파일이나 패턴 지정 (예: version_compare)

예시:
    $0                           # 모든 테스트 실행 (integration 제외)
    $0 -i                        # 통합 테스트 포함 모든 테스트 실행
    $0 -p                        # 병렬로 모든 테스트 실행 
    $0 -p -j 8                   # 8개 job으로 병렬 실행
    $0 -f tap                    # TAP 형식으로 출력
    $0 version_compare           # version_compare 관련 테스트만 실행
    $0 -v -f junit logging       # 로깅 테스트를 JUnit 형식으로 자세히 실행

환경변수:
    VERBOSE=true                 자세한 출력 활성화
    RUN_INTEGRATION=true         통합 테스트 포함
    FORCE_INTEGRATION=true       Docker 통합 테스트 강제 실행
    PARALLEL=true                병렬 실행 활성화
    CI=true                      CI 환경 (자동으로 TAP 형식 사용)

테스트 파일:
    • platform_detection_test.bats    - 플랫폼 감지 테스트
    • version_compare_test.bats        - 버전 비교 테스트
    • logging_functions_test.bats      - 로깅 함수 테스트
    • command_checks_test.bats         - 명령어 체크 테스트
    • file_operations_test.bats        - 파일 작업 테스트
    • docker_integration_test.bats     - Docker 통합 테스트 (-i 필요)
EOF
}

# BATS 존재 확인
check_bats() {
    if [[ ! -f "$BATS_PATH" ]]; then
        log_error "BATS를 찾을 수 없습니다: $BATS_PATH"
        log_info "BATS 설치 방법:"
        log_info "  pnpm install (또는 npm install)"
        exit 1
    fi
    
    if [[ ! -x "$BATS_PATH" ]]; then
        log_warn "BATS에 실행 권한이 없습니다. 권한을 설정합니다..."
        chmod +x "$BATS_PATH"
    fi
}

# 테스트 디렉토리 확인
check_test_directories() {
    if [[ ! -d "$TEST_DIR" ]]; then
        log_error "BATS 테스트 디렉토리를 찾을 수 없습니다: $TEST_DIR"
        log_info "BATS 테스트가 올바른 위치에 있는지 확인하세요."
        exit 1
    fi
    
    local helper_dir="tests/test_helper"
    if [[ ! -d "$helper_dir" ]]; then
        log_error "BATS 헬퍼 디렉토리를 찾을 수 없습니다: $helper_dir"
        log_info "BATS 헬퍼 라이브러리가 설치되어 있는지 확인하세요."
        exit 1
    fi
}

# 테스트 파일 목록 수집
collect_test_files() {
    local pattern="$1"
    local include_integration="$2"
    local files=()
    
    # 모든 .bats 파일 찾기
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        
        # 통합 테스트 제외 처리
        if [[ "$basename" == "docker_integration_test.bats" && "$include_integration" != "true" ]]; then
            continue
        fi
        
        # 패턴 매칭
        if [[ -z "$pattern" || "$basename" =~ $pattern ]]; then
            files+=("$file")
        fi
    done < <(find "$TEST_DIR" -name "*.bats" -type f -print0 2>/dev/null)
    
    printf '%s\n' "${files[@]}"
}

# BATS 명령어 구성
build_bats_command() {
    local test_files=("$@")
    local cmd="$BATS_PATH"
    
    # 형식 설정
    case "$FORMAT" in
        "tap")
            cmd="$cmd --formatter tap"
            ;;
        "junit")
            cmd="$cmd --formatter junit"
            ;;
        "pretty"|*)
            cmd="$cmd --formatter pretty"
            ;;
    esac
    
    # 병렬 실행
    if [[ "$PARALLEL" == "true" ]]; then
        cmd="$cmd --jobs $JOBS"
    fi
    
    # Verbose 설정
    if [[ "$VERBOSE" == "true" ]]; then
        cmd="$cmd --verbose-run"
    fi
    
    # CI 환경 자동 감지
    if [[ "${CI:-false}" == "true" && "$FORMAT" == "pretty" ]]; then
        cmd="${cmd/--formatter pretty/--formatter tap}"
        log_info "CI 환경 감지: TAP 형식으로 자동 전환"
    fi
    
    # 테스트 파일들 추가
    cmd="$cmd ${test_files[*]}"
    
    echo "$cmd"
}

# 테스트 실행
run_tests() {
    local test_files=("$@")
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_warn "실행할 테스트 파일이 없습니다."
        return 0
    fi
    
    log_header "BATS 테스트 실행 시작"
    echo "📁 테스트 디렉토리: $TEST_DIR"
    echo "📊 실행할 파일 수: ${#test_files[@]}"
    echo "⚙️  병렬 실행: $([ "$PARALLEL" == "true" ] && echo "Yes (${JOBS} jobs)" || echo "No")"
    echo "📋 출력 형식: $FORMAT"
    echo ""
    
    # 통합 테스트 경고
    for file in "${test_files[@]}"; do
        if [[ "$(basename "$file")" == "docker_integration_test.bats" ]]; then
            log_warn "🐳 Docker 통합 테스트가 포함됩니다."
            echo "   • Docker daemon이 실행 중이어야 합니다."
            echo "   • 네트워크 연결이 필요할 수 있습니다."
            echo "   • 강제 실행: FORCE_INTEGRATION=true"
            echo ""
            break
        fi
    done
    
    # BATS 명령어 구성 및 실행 (상대 경로 조정)
    local bats_cmd
    local relative_files=()
    
    # 파일 경로를 상대 경로로 변경
    for file in "${test_files[@]}"; do
        relative_files+=("$(basename "$file")")
    done
    
    # BATS 경로를 현재 디렉토리 기준으로 조정
    local adjusted_bats_path="../../node_modules/.bin/bats"
    bats_cmd=$(BATS_PATH="$adjusted_bats_path" build_bats_command "${relative_files[@]}")
    
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "실행 명령어: $bats_cmd"
        echo ""
    fi
    
    # 테스트 실행
    local start_time=$(date +%s)
    
    if eval "$bats_cmd"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo ""
        log_info "🎉 모든 테스트가 성공적으로 완료되었습니다! (${duration}초 소요)"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo ""
        log_error "💥 일부 테스트가 실패했습니다. (${duration}초 소요)"
        return 1
    fi
}

# 테스트 파일 목록 출력
list_test_files() {
    log_header "사용 가능한 BATS 테스트 파일"
    echo ""
    
    if [[ ! -d "$TEST_DIR" ]]; then
        log_error "테스트 디렉토리가 없습니다: $TEST_DIR"
        return 1
    fi
    
    local files
    mapfile -t files < <(find "$TEST_DIR" -name "*.bats" -type f | sort)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        log_warn "BATS 테스트 파일이 없습니다."
        return 0
    fi
    
    for file in "${files[@]}"; do
        local basename=$(basename "$file")
        local description=""
        
        case "$basename" in
            "platform_detection_test.bats")
                description="플랫폼 및 CI 환경 감지 테스트"
                ;;
            "version_compare_test.bats")
                description="버전 비교 함수 테스트"
                ;;
            "logging_functions_test.bats")
                description="로깅 함수 테스트"
                ;;
            "command_checks_test.bats")
                description="명령어 존재 확인 및 버전 체크 테스트"
                ;;
            "file_operations_test.bats")
                description="파일 작업 및 스크립트 실행 테스트"
                ;;
            "docker_integration_test.bats")
                description="Docker 통합 테스트 (Docker daemon 필요)"
                ;;
            *)
                description="설명 없음"
                ;;
        esac
        
        echo "  • $basename - $description"
    done
    
    echo ""
    echo "사용법: $0 [test_pattern]"
    echo "예시: $0 version  # version 관련 테스트만 실행"
}

# 시스템 정보 출력
show_system_info() {
    echo "🔍 시스템 정보:"
    echo "  • OS: $(uname -s) $(uname -m)"
    echo "  • Bash: $BASH_VERSION"
    echo "  • BATS: $($BATS_PATH --version 2>/dev/null || echo 'Unknown')"
    echo "  • Node.js: $(node --version 2>/dev/null || echo 'Not available')"
    echo "  • 작업 디렉토리: $(pwd)"
    echo "  • 테스트 디렉토리: $TEST_DIR"
    
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version 2>/dev/null || echo "Docker not available")
        echo "  • Docker: $docker_version"
        if docker info >/dev/null 2>&1; then
            echo "    ✅ Docker daemon 실행 중"
        else
            echo "    ❌ Docker daemon 정지됨"
        fi
    else
        echo "  • Docker: Not installed"
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
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -j|--jobs)
                JOBS="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            --list)
                list_test_files
                exit 0
                ;;
            --version)
                echo "Shell Tests Runner - BATS Edition v2.0.0"
                $BATS_PATH --version 2>/dev/null || echo "BATS: Unknown version"
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
    check_bats
    check_test_directories
    
    # 시스템 정보 출력
    if [[ "$VERBOSE" == "true" ]]; then
        show_system_info
    fi
    
    # 테스트 파일 수집
    log_info "BATS 테스트 파일을 수집하는 중..."
    local test_files
    mapfile -t test_files < <(collect_test_files "$pattern" "$RUN_INTEGRATION")
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_warn "실행할 테스트 파일이 없습니다."
        if [[ -n "$pattern" ]]; then
            log_info "패턴 '$pattern'과 일치하는 테스트를 찾을 수 없습니다."
            echo ""
            log_info "사용 가능한 테스트 파일 목록을 보려면: $0 --list"
        fi
        exit 0
    fi
    
    # 테스트 실행
    cd "$TEST_DIR"
    run_tests "${test_files[@]}"
}

# 스크립트 실행
main "$@" 