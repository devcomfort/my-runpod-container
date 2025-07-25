# 변수 정의
variable "RELEASE" {
  default = "0.2"
}

variable "DOCKER_HUB_USERNAME" {
  default = "devcomfort"
}

variable "GHCR_USERNAME" {
  default = "devcomfort"
}

# CI/CD 호환성을 위한 추가 변수
variable "REGISTRY" {
  default = "docker.io"
}

variable "CACHE_FROM" {
    default = "type=gha"
}

variable "CACHE_TO" {
    default = "type=gha,mode=max"
}

# 개발 도구 버전 관리 (versions.env와 동기화)
variable "GO_VERSION" {
    default = "1.23.4"
}

variable "TINYGO_VERSION" {
    default = "0.38.0"  
}

variable "GH_VERSION" {
    default = "2.76.1"
}

# 빌드 최적화 변수
variable "BUILD_PLATFORM" {
  default = ""
}

variable "MAX_PARALLELISM" {
  default = "4"
}

group "default" {
  targets = ["cpu", "11-1-1", "11-8-0", "12-1-0", "12-2-0", "12-4-1", "12-5-1", "12-6-2"]
}

target "cpu" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cpu",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cpu"
    ]
    platforms = ["linux/amd64", "linux/arm64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cpu"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cpu,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "ubuntu:20.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "11-1-1" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.1.1",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.1.1"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda11"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda11,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:11.1.1-devel-ubuntu20.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "11-8-0" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.8.0",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.8.0"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda11"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda11,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:11.8.0-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "12-1-0" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.1.0",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.1.0"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.1.0-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "12-2-0" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.2.0",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.2.0"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.2.0-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "12-4-1" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.4.1",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.4.1"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.4.1-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "12-5-1" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.5.1",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.5.1"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.5.1-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}

target "12-6-2" {
    dockerfile = "Dockerfile"
    tags = [
        "${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.6.2",
        "ghcr.io/${GHCR_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.6.2"
    ]
    platforms = ["linux/amd64"]
    cache-from = [
        "${CACHE_FROM}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12"
    ]
    cache-to = [
        "${CACHE_TO}",
        "type=registry,ref=${REGISTRY}/${DOCKER_HUB_USERNAME}/personal-runpod-environment:cache-cuda12,mode=max"
    ]
    target = "final"
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.6.2-devel-ubuntu22.04"
        BUILDKIT_INLINE_CACHE = "1"
        GO_VERSION = "${GO_VERSION}"
        TINYGO_VERSION = "${TINYGO_VERSION}"
        GH_VERSION = "${GH_VERSION}"
        INSTALL_SLURM = "true"
    }
    attest = [
        "type=provenance",
        "type=sbom"
    ]
}