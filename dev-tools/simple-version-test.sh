#!/bin/bash

# 간단한 버전 통합 테스트
set -euo pipefail

echo "🔬 .versions.env 통합 테스트"
echo "=========================="

# .versions.env 파일 경로 자동 감지
VERSIONS_FILE=""
if [ -f ".versions.env" ]; then
    VERSIONS_FILE=".versions.env"
elif [ -f "../.versions.env" ]; then
    VERSIONS_FILE="../.versions.env"
else
    echo "❌ .versions.env 파일을 찾을 수 없습니다"
    echo "   현재 디렉토리: $(pwd)"
    echo "   확인한 경로: .versions.env, ../.versions.env"
    exit 1
fi

# .versions.env 로드
source "$VERSIONS_FILE"
echo "✅ .versions.env 로드 성공 (경로: $VERSIONS_FILE)"
echo "   GO_VERSION=$GO_VERSION"
echo "   TINYGO_VERSION=$TINYGO_VERSION"  
echo "   GH_VERSION=$GH_VERSION"

echo ""

# Dockerfile 버전 확인 (상위 디렉토리 또는 현재 디렉토리)
DOCKERFILE_PATH=""
if [ -f "Dockerfile" ]; then
    DOCKERFILE_PATH="Dockerfile"
elif [ -f "../Dockerfile" ]; then
    DOCKERFILE_PATH="../Dockerfile"
else
    echo "❌ Dockerfile을 찾을 수 없습니다"
    exit 1
fi

echo "📄 Dockerfile 버전 확인 (경로: $DOCKERFILE_PATH):"
DOCKERFILE_GO=$(grep "ARG GO_VERSION=" "$DOCKERFILE_PATH" | cut -d'"' -f2)
DOCKERFILE_TINYGO=$(grep "ARG TINYGO_VERSION=" "$DOCKERFILE_PATH" | cut -d'"' -f2)
DOCKERFILE_GH=$(grep "ARG GH_VERSION=" "$DOCKERFILE_PATH" | cut -d'"' -f2)

echo "   Dockerfile GO_VERSION=$DOCKERFILE_GO $([ "$GO_VERSION" = "$DOCKERFILE_GO" ] && echo "✅" || echo "❌")"
echo "   Dockerfile TINYGO_VERSION=$DOCKERFILE_TINYGO $([ "$TINYGO_VERSION" = "$DOCKERFILE_TINYGO" ] && echo "✅" || echo "❌")"
echo "   Dockerfile GH_VERSION=$DOCKERFILE_GH $([ "$GH_VERSION" = "$DOCKERFILE_GH" ] && echo "✅" || echo "❌")"

echo ""

# docker-bake.hcl 버전 확인 (상위 디렉토리 또는 현재 디렉토리)
BAKE_FILE=""
if [ -f "docker-bake.hcl" ]; then
    BAKE_FILE="docker-bake.hcl"
elif [ -f "../docker-bake.hcl" ]; then
    BAKE_FILE="../docker-bake.hcl"
else
    echo "❌ docker-bake.hcl을 찾을 수 없습니다"
    exit 1
fi

echo "🐳 docker-bake.hcl 기본값 확인 (경로: $BAKE_FILE):"
BAKE_GO=$(grep -A1 'variable "GO_VERSION"' "$BAKE_FILE" | grep default | sed 's/.*"\([^"]*\)".*/\1/')
BAKE_TINYGO=$(grep -A1 'variable "TINYGO_VERSION"' "$BAKE_FILE" | grep default | sed 's/.*"\([^"]*\)".*/\1/')
BAKE_GH=$(grep -A1 'variable "GH_VERSION"' "$BAKE_FILE" | grep default | sed 's/.*"\([^"]*\)".*/\1/')

echo "   docker-bake GO_VERSION=$BAKE_GO $([ "$GO_VERSION" = "$BAKE_GO" ] && echo "✅" || echo "❌")"
echo "   docker-bake TINYGO_VERSION=$BAKE_TINYGO $([ "$TINYGO_VERSION" = "$BAKE_TINYGO" ] && echo "✅" || echo "❌")"
echo "   docker-bake GH_VERSION=$BAKE_GH $([ "$GH_VERSION" = "$BAKE_GH" ] && echo "✅" || echo "❌")"

echo ""
echo "🎯 테스트 완료!" 