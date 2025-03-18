# 기본 설정
RELEASE ?= 0.2
DOCKER_HUB_USERNAME ?= devcomfort
DEBUG ?= 0

# 디버그 옵션 처리
ifdef DEBUG
  ifeq ($(DEBUG), 1)
    DEBUG_FLAG = --debug
  else
    DEBUG_FLAG =
  endif
else
  DEBUG_FLAG =
endif

# 빌드 대상 목록
TARGETS := cpu 11-1-1 11-8-0 12-1-0 12-2-0 12-4-1 12-5-1 12-6-2

# 도커 빌드
.PHONY: build
build:
	@docker buildx bake --file docker-bake.hcl $(DEBUG_FLAG)

# 순차 빌드
.PHONY: build-seq
build-seq:
	@for target in $(TARGETS); do \
		echo "=== $$target 빌드 시작 ==="; \
		docker buildx bake $$target --file docker-bake.hcl $(DEBUG_FLAG) || exit 1; \
	done

# 순차 푸시
.PHONY: push-seq
push-seq:
	@for target in $(TARGETS); do \
		echo "=== $$target 푸시 시작 ==="; \
		docker buildx bake $$target --file docker-bake.hcl --push $(DEBUG_FLAG) || exit 1; \
	done

# 순차 전체 작업
.PHONY: all-seq
all-seq: build-seq push-seq

# 특정 타겟 빌드
.PHONY: $(TARGETS)
$(TARGETS):
	@docker buildx bake $@ --file docker-bake.hcl $(DEBUG_FLAG)

# 도커 이미지 푸시
.PHONY: push
push:
	@docker buildx bake --file docker-bake.hcl --push $(DEBUG_FLAG)

# 특정 타겟 푸시
.PHONY: push-$(TARGETS)
push-%:
	@docker buildx bake $* --file docker-bake.hcl --push $(DEBUG_FLAG)

# 전체 정리
.PHONY: clean
clean:
	@docker system prune -f

# 도움말
.PHONY: help
help:
	@echo "사용 가능한 명령어:"
	@echo "  build            : 도커 이미지를 빌드합니다."
	@echo "  <target>        : 특정 타겟을 빌드합니다. (예: make 11-1-1)"
	@echo "  push             : 도커 이미지를 푸시합니다."
	@echo "  push-<target>   : 특정 타겟을 푸시합니다. (예: make push-11-1-1)"
	@echo "  build-seq       : 모든 타겟을 순차적으로 빌드합니다."
	@echo "  push-seq        : 모든 타겟을 순차적으로 푸시합니다."
	@echo "  all-seq         : 모든 타겟에 대해 빌드와 푸시를 순차적으로 수행합니다."
	@echo "  clean           : 모든 도커 리소스를 정리합니다."
	@echo "  help             : 이 도움말을 표시합니다."
	@echo ""
	@echo "환경 변수:"
	@echo "  DEBUG=1         : 디버그 모드 활성화 (예: make build DEBUG=1)"
	@echo "  RELEASE=x.x     : 릴리스 버전 설정 (예: make build RELEASE=0.3)"
	@echo "  DOCKER_HUB_USERNAME=사용자명 : Docker Hub 사용자명 설정"