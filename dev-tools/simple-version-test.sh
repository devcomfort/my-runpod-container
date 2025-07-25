#!/bin/bash

# 간단한 버전 통합 테스트
set -euo pipefail

echo "🔬 .versions.env 통합 테스트"
echo "=========================="

# .versions.env 로드 (상위 디렉토리에서)
if [ -f "../.versions.env" ]; then
    source ../.versions.env
    echo "✅ .versions.env 로드 성공"
    echo "   GO_VERSION=$GO_VERSION"
    echo "   TINYGO_VERSION=$TINYGO_VERSION"  
    echo "   GH_VERSION=$GH_VERSION"
    echo "   BUILDX_VERSION=$BUILDX_VERSION"
else
    echo "❌ ../.versions.env 파일이 없습니다"
    exit 1
fi

echo ""

# Dockerfile 버전 확인 (상위 디렉토리에서)
echo "📄 Dockerfile 버전 확인:"
DOCKERFILE_GO=$(grep "ARG GO_VERSION=" ../Dockerfile | cut -d'"' -f2)
DOCKERFILE_TINYGO=$(grep "ARG TINYGO_VERSION=" ../Dockerfile | cut -d'"' -f2)
DOCKERFILE_GH=$(grep "ARG GH_VERSION=" ../Dockerfile | cut -d'"' -f2)

echo "   Dockerfile GO_VERSION=$DOCKERFILE_GO $([ "$GO_VERSION" = "$DOCKERFILE_GO" ] && echo "✅" || echo "❌")"
echo "   Dockerfile TINYGO_VERSION=$DOCKERFILE_TINYGO $([ "$TINYGO_VERSION" = "$DOCKERFILE_TINYGO" ] && echo "✅" || echo "❌")"
echo "   Dockerfile GH_VERSION=$DOCKERFILE_GH $([ "$GH_VERSION" = "$DOCKERFILE_GH" ] && echo "✅" || echo "❌")"

echo ""

# docker-bake.hcl 버전 확인 (상위 디렉토리에서)
echo "🐳 docker-bake.hcl 기본값 확인:"
BAKE_GO=$(grep -A1 'variable "GO_VERSION"' ../docker-bake.hcl | grep default | sed 's/.*"\([^"]*\)".*/\1/')
BAKE_TINYGO=$(grep -A1 'variable "TINYGO_VERSION"' ../docker-bake.hcl | grep default | sed 's/.*"\([^"]*\)".*/\1/')
BAKE_GH=$(grep -A1 'variable "GH_VERSION"' ../docker-bake.hcl | grep default | sed 's/.*"\([^"]*\)".*/\1/')

echo "   docker-bake GO_VERSION=$BAKE_GO $([ "$GO_VERSION" = "$BAKE_GO" ] && echo "✅" || echo "❌")"
echo "   docker-bake TINYGO_VERSION=$BAKE_TINYGO $([ "$TINYGO_VERSION" = "$BAKE_TINYGO" ] && echo "✅" || echo "❌")"
echo "   docker-bake GH_VERSION=$BAKE_GH $([ "$GH_VERSION" = "$BAKE_GH" ] && echo "✅" || echo "❌")"

echo ""
echo "🎯 테스트 완료!" 