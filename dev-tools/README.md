# 📁 Scripts Directory Guide

## 🚨 중요: 파일 분류 안내

> **이 디렉토리는 현재 개발용과 컨테이너 빌드용 파일이 혼재되어 있습니다.**  
> **향후 구조 개선 예정 → [PROJECT_RESTRUCTURE.md](../PROJECT_RESTRUCTURE.md) 참조**

## 🎯 현재 파일 분류

### 🐳 컨테이너 빌드에 포함되는 파일들

**이 파일들은 Docker 이미지에 복사되어 컨테이너 런타임에 사용됩니다.**

| 파일 | 용도 | Docker 복사 위치 | 실행 시점 |
|------|------|------------------|-----------|
| `start.sh` | 컨테이너 진입점 | `/start.sh` | 컨테이너 시작 |
| `post_start.sh` | 시작 후 초기화 | `/post_start.sh` | 시작 후 실행 |

#### Dockerfile 참조
```dockerfile
COPY scripts/post_start.sh /
COPY scripts/start.sh /
```

### 🔧 개발/프로젝트 관리 전용 파일들

**이 파일들은 Docker 빌드에 포함되지 않으며, 개발자가 로컬에서만 사용합니다.**

| 파일 | 용도 | 실행 위치 | 대상 |
|------|------|-----------|------|
| `check-dev-requirements.sh` | 개발 환경 검증 | 개발자 로컬 | 개발자 |
| `update-container-versions.py` | 컨테이너 도구 버전 관리 | 개발자 로컬 | 프로젝트 팀 |
| `simple-version-test.sh` | 빠른 버전 일관성 테스트 | 개발자 로컬 | 개발자 |
| `test-version-integration.sh` | 상세 통합 테스트 | 개발자 로컬 | 개발자 |

#### 사용 예시

```bash
# 🔧 개발자 워크플로우
./scripts/check-dev-requirements.sh           # 환경 체크
./scripts/simple-version-test.sh              # 빠른 테스트
python3 scripts/update-container-versions.py  # 버전 관리

# 🐳 컨테이너에서는 자동 실행
# /start.sh → /post_start.sh 순서로 실행됨
```

## 🚀 향후 구조 개선 계획

### 단계 1: 하위 디렉토리 생성 (즉시 가능)
```
scripts/
├── container/          # 컨테이너 빌드용
│   ├── start.sh
│   └── post_start.sh
└── dev/               # 개발 도구
    ├── check-dev-requirements.sh
    ├── update-container-versions.py
    ├── simple-version-test.sh
    └── test-version-integration.sh
```

### 단계 2: 완전 분리 (향후)
```
personal-runpod-image/
├── container/         # 모든 빌드 관련 파일
├── dev-tools/         # 모든 개발 도구
└── docs/              # 모든 문서
```

## ⚠️ 개발자 주의사항

### ✅ 올바른 파일 수정

```bash
# 컨테이너 동작 수정 시
vim scripts/start.sh      # 컨테이너 진입점
vim scripts/post_start.sh # 컨테이너 초기화

# 개발 환경 개선 시  
vim scripts/check-dev-requirements.sh         # 환경 체크
vim scripts/update-container-versions.py      # 버전 관리
```

### ❌ 피해야 할 실수

```bash
# ❌ 개발 도구를 컨테이너용으로 착각
# check-dev-requirements.sh는 Docker에 복사되지 않음!

# ❌ 컨테이너 스크립트를 로컬에서 직접 실행
# start.sh는 컨테이너 내부 전용!
```

## 🔍 파일 확인 방법

```bash
# Docker에 복사되는 파일 확인
grep "COPY scripts/" Dockerfile

# 개발용 파일 목록
ls scripts/ | grep -E "(check-dev|update-container|test-|simple-)"

# 컨테이너용 파일 목록  
ls scripts/ | grep -E "(start|post_start)"
```

## 📞 문의사항

- 파일 분류가 헷갈린다면: `PROJECT_RESTRUCTURE.md` 참조
- 새 스크립트 추가 시: 용도에 맞는 분류 확인 후 추가
- 구조 개선 제안: 프로젝트 이슈 트래커에 문의 