#!/bin/bash

# 개발자 로컬 환경 요구사항 체크 스크립트
# Docker, Buildx, Git 등 개발자가 직접 관리해야 하는 도구들을 검증

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
log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }

# 테스트 결과 변수
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# 버전 비교 함수
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

# 체크 함수
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
    
    echo "   발견된 버전: $version"
    
    # 최소 버전 체크
    if version_compare "$version" "$min_version" ">="; then
        # 권장 버전 체크
        if version_compare "$version" "$recommended_version" ">="; then
            log_info "✅ $check_name: $version (권장 버전 이상)"
            ((CHECKS_PASSED++))
        else
            log_warn "⚠️  $check_name: $version (최소 요구사항 만족, 권장 버전: $recommended_version)"
            ((CHECKS_WARNING++))
        fi
    else
        log_error "❌ $check_name: $version (최소 요구 버전: $min_version)"
        echo "   업데이트 방법: dev-requirements.md 참조"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# 선택적 도구 체크
check_optional_tool() {
    local tool_name="$1" 
    local command="$2"
    
    log_check "선택적 도구 검사: $tool_name"
    
    if command -v "$command" >/dev/null 2>&1; then
        local version
        case $command in
            "gh")
                version=$(gh --version 2>/dev/null | head -1 | sed 's/gh version \([0-9.]*\).*/\1/' || echo "unknown")
                ;;
            "code")
                version=$(code --version 2>/dev/null | head -1 || echo "unknown")
                ;;
            *)
                version="unknown"
                ;;
        esac
        log_info "✅ $tool_name: $version (설치됨)"
    else
        log_info "ℹ️  $tool_name: 미설치 (선택사항)"
    fi
}

# Docker 특별 검사
check_docker_functionality() {
    log_check "Docker 기능 검사"
    
    # Docker 서비스 상태
    if ! docker info >/dev/null 2>&1; then
        log_error "❌ Docker 서비스가 실행되지 않음"
        echo "   해결 방법: sudo systemctl start docker"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    # Docker 권한 체크
    if ! docker ps >/dev/null 2>&1; then
        log_error "❌ Docker 권한 부족"
        echo "   해결 방법: sudo usermod -aG docker \$USER && newgrp docker"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    # Buildx 플러그인 체크
    if ! docker buildx ls >/dev/null 2>&1; then
        log_error "❌ Docker Buildx 플러그인 문제"
        echo "   해결 방법: docker buildx install"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    log_info "✅ Docker 기능 정상"
    ((CHECKS_PASSED++))
}

# 메인 실행
main() {
    echo "🔍 개발자 로컬 환경 요구사항 검사"
    echo "========================================"
    echo
    
    # 필수 도구들 체크
    log_info "📋 필수 도구 검사"
    echo
    
    run_check "Docker Engine" "docker --version" "24.0" "26.0"
    run_check "Docker Buildx" "docker buildx version" "0.25.0" "0.26.1"  
    run_check "Git" "git --version" "2.40" "2.45"
    
    echo
    
    # Docker 기능 검사
    check_docker_functionality
    
    echo
    
    # 선택적 도구들 체크
    log_info "📋 선택적 도구 검사"
    echo
    
    check_optional_tool "GitHub CLI" "gh"
    check_optional_tool "VS Code" "code"
    
    echo
    
    # 프로젝트 특화 검사
    log_info "📋 프로젝트 파일 검사"
    echo
    
    # .versions.env 파일 체크 (상위 디렉토리에서)
    if [ -f "../.versions.env" ]; then
        log_info "✅ .versions.env 파일 존재"
        ((CHECKS_PASSED++))
    else
        log_error "❌ ../.versions.env 파일 없음"
        ((CHECKS_FAILED++))
    fi
    
        # docker-bake.hcl 파일 체크 (상위 디렉토리에서)
    if [ -f "../docker-bake.hcl" ]; then
        log_info "✅ docker-bake.hcl 파일 존재"
        ((CHECKS_PASSED++))

        # 기본 구문 검사 (상위 디렉토리에서 실행)
        if (cd .. && docker buildx bake --print cpu >/dev/null 2>&1); then
            log_info "✅ docker-bake.hcl 구문 정상"
            ((CHECKS_PASSED++))
        else
            log_error "❌ docker-bake.hcl 구문 오류"
            ((CHECKS_FAILED++))
        fi
    else
        log_error "❌ ../docker-bake.hcl 파일 없음"
        ((CHECKS_FAILED++))
    fi
    
    echo
    echo "========================================"
    echo "🎯 검사 결과 요약"
    echo "========================================"
    
    log_info "✅ 통과: $CHECKS_PASSED개"
    
    if [ $CHECKS_WARNING -gt 0 ]; then
        log_warn "⚠️  경고: $CHECKS_WARNING개"
    fi
    
    if [ $CHECKS_FAILED -gt 0 ]; then
        log_error "❌ 실패: $CHECKS_FAILED개"
        echo
        log_error "🔧 문제 해결:"
        echo "   1. dev-requirements.md 문서 참조"
        echo "   2. 실패한 도구들 업데이트/설치"
        echo "   3. 스크립트 재실행으로 검증"
        exit 1
    else
        log_info "🎉 모든 검사를 통과했습니다!"
        echo
        log_info "📊 개발 환경 상태:"
        echo "   - Docker 환경: 정상"
        echo "   - 빌드 도구: 정상"  
        echo "   - 프로젝트 파일: 정상"
        echo
                            log_info "다음 단계:"
                    echo "   cd .. && docker buildx bake --print cpu  # 빌드 설정 확인"
                    echo "   cd .. && docker buildx bake cpu          # 실제 빌드 테스트"
        exit 0
    fi
}

# 도움말
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "개발자 로컬 환경 요구사항 검사 도구"
    echo
    echo "사용법: $0"
    echo
    echo "검사 항목:"
    echo "  - Docker Engine 버전 및 상태"
    echo "  - Docker Buildx 버전 및 기능"
    echo "  - Git 버전"
    echo "  - 선택적 도구들 (GitHub CLI, VS Code)"
    echo "  - 프로젝트 설정 파일들"
    echo
    echo "자세한 요구사항: dev-requirements.md 참조"
    exit 0
fi

main "$@" 