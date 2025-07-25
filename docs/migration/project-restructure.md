# 📁 프로젝트 구조 재구성 제안

## 🎯 목표

> **컨테이너 빌드용 파일과 프로젝트 관리용 파일을 명확히 분리하여 혼란 방지**

## 📊 현재 문제점

### ❌ 현재 구조의 문제
- `scripts/` 디렉토리에 개발용과 빌드용 파일 혼재
- 개발자가 어떤 파일이 Docker에 포함되는지 헷갈림
- 프로젝트 관리 파일들이 여러 곳에 분산

## 🚀 제안된 새 구조

### 📁 **Option 1: 3계층 분리 (권장)**

```
personal-runpod-image/
├── 🐳 container/                    # 컨테이너 빌드 전용
│   ├── scripts/
│   │   ├── start.sh                 # 컨테이너 진입점
│   │   └── post_start.sh            # 시작 후 스크립트
│   ├── src/                         # 런타임 바이너리
│   │   ├── serve-remote.py
│   │   ├── start-vscode
│   │   └── vscode-server-setup.sh
│   └── proxy/                       # nginx 설정
│       ├── nginx.conf
│       └── readme.html
│
├── 🔧 dev-tools/                    # 개발/관리 도구
│   ├── check-dev-requirements.sh
│   ├── update-container-versions.py
│   ├── simple-version-test.sh
│   └── test-version-integration.sh
│
├── 📚 docs/                         # 문서 및 자료
│   ├── dev-requirements.md
│   ├── TOOL_MANAGEMENT.md
│   ├── DEVELOPMENT.md
│   ├── logo/
│   └── guides/
│
└── 🔧 빌드 설정 (루트)
    ├── Dockerfile                   # container/ 참조
    ├── docker-bake.hcl
    ├── .versions.env
    └── setup_multi_architecture_build.sh
```

### 📁 **Option 2: 간단한 분리**

```
personal-runpod-image/
├── 🐳 build/                        # 빌드 관련 모든 것
│   ├── container-scripts/
│   │   ├── start.sh
│   │   └── post_start.sh
│   ├── runtime-src/
│   │   └── [src 파일들]
│   └── proxy/
│       └── [proxy 파일들]
│
├── 🔧 dev-scripts/                  # 개발 도구만
│   ├── check-dev-requirements.sh
│   ├── update-container-versions.py
│   └── [테스트 스크립트들]
│
└── [기존 루트 파일들 유지]
```

### 📁 **Option 3: 최소 변경**

```
personal-runpod-image/
├── scripts/
│   ├── 🐳 container/               # 컨테이너용 하위 디렉토리
│   │   ├── start.sh
│   │   └── post_start.sh
│   └── 🔧 dev/                     # 개발용 하위 디렉토리
│       ├── check-dev-requirements.sh
│       ├── update-container-versions.py
│       └── [테스트 스크립트들]
└── [기타 기존 구조 유지]
```

## 🔄 마이그레이션 계획

### 단계 1: 파일 이동

#### Option 1 선택 시:
```bash
# 새 디렉토리 생성
mkdir -p container/scripts container/src container/proxy
mkdir -p dev-tools docs/guides

# 컨테이너 빌드 파일 이동
mv scripts/start.sh container/scripts/
mv scripts/post_start.sh container/scripts/
mv src/* container/src/
mv proxy/* container/proxy/

# 개발 도구 이동
mv scripts/check-dev-requirements.sh dev-tools/
mv scripts/update-container-versions.py dev-tools/
mv scripts/simple-version-test.sh dev-tools/
mv scripts/test-version-integration.sh dev-tools/

# 문서 이동
mv dev-requirements.md docs/
mv TOOL_MANAGEMENT.md docs/
mv DEVELOPMENT.md docs/
mv logo docs/
```

### 단계 2: Dockerfile 수정

```dockerfile
# 기존
COPY scripts/start.sh /
COPY scripts/post_start.sh /
COPY src/* /usr/local/bin/
COPY proxy/nginx.conf /etc/nginx/nginx.conf

# 새로운 구조 (Option 1)
COPY container/scripts/start.sh /
COPY container/scripts/post_start.sh /
COPY container/src/* /usr/local/bin/
COPY container/proxy/nginx.conf /etc/nginx/nginx.conf
```

### 단계 3: 스크립트 경로 업데이트

```bash
# README.md 및 문서들의 경로 업데이트
# GitHub Actions workflow 경로 업데이트
# 기타 참조 경로들 일괄 수정
```

## 📋 각 옵션별 장단점

| 측면 | Option 1 (3계층) | Option 2 (간단) | Option 3 (최소) |
|------|------------------|-----------------|-----------------|
| **명확성** | ✅ 매우 높음 | ✅ 높음 | ⚠️ 중간 |
| **학습 곡선** | ⚠️ 높음 | ✅ 낮음 | ✅ 매우 낮음 |
| **확장성** | ✅ 매우 좋음 | ✅ 좋음 | ⚠️ 제한적 |
| **변경 범위** | ❌ 큼 | ⚠️ 중간 | ✅ 작음 |
| **유지보수성** | ✅ 매우 좋음 | ✅ 좋음 | ⚠️ 중간 |

## 🎯 권장사항

### 🥇 **1순위: Option 1 (3계층 분리)**

**장점:**
- 완전한 관심사 분리
- 미래 확장성 우수
- 새 개발자도 쉽게 이해

**단점:**
- 초기 마이그레이션 비용
- 기존 스크립트/문서 수정 필요

### 🥈 **2순위: Option 3 (최소 변경)**

**장점:**
- 즉시 적용 가능
- 기존 구조 유지
- 낮은 학습 비용

**단점:**
- 근본적 해결책 아님
- 장기적으로 혼란 가능성

## 🚀 구현 순서

### 즉시 가능한 개선
1. `scripts/README.md`에 파일 분류 명시
2. 개발용 스크립트에 주석 추가
3. Dockerfile 주석으로 복사되는 파일 명시

### 단계적 마이그레이션
1. **Week 1**: Option 3으로 하위 디렉토리 생성
2. **Week 2**: 파일 이동 및 경로 업데이트
3. **Week 3**: 문서 정리 및 검증
4. **Week 4**: 필요시 Option 1으로 완전 분리

## 🎉 최종 목표

> **개발자가 보자마자 "이 파일은 컨테이너용, 저 파일은 개발용"을 즉시 알 수 있는 직관적 구조** 