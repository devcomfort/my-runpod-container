# Makefile for building and pushing Docker images

# 기본 변수 설정
IMAGE_NAME = devcomfort/personal-runpod-environment
BASE_IMAGE = ubuntu:22.04

# 기본 버전 설정 (인자가 없을 경우) -
VERSION ?= 0.2

# 빌드 명령
build:
	@echo "Building Docker image: $(IMAGE_NAME):$(VERSION)"
	docker build -t $(IMAGE_NAME):$(VERSION) . --build-arg BASE_IMAGE=$(BASE_IMAGE)

# 푸시 명령
push:
	@echo "Pushing Docker image: $(IMAGE_NAME):$(VERSION)"
	docker push $(IMAGE_NAME):$(VERSION)

# 빌드 및 푸시를 한 번에 수행하는 명령
all: build push

# 사용 방법
help:
	@echo "Usage:"
	@echo "  make build VERSION=<version>  # Build the Docker image with the specified version"
	@echo "  make push VERSION=<version>   # Push the Docker image with the specified version"
	@echo "  make all VERSION=<version>    # Build and push the Docker image"
	@echo "  make help                     # Show this help message"
