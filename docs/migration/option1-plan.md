# 🚀 Option 1: 완전 분리 마이그레이션 계획

## 🎯 목표 구조

```
personal-runpod-image/
├── 🐳 container/                    # 컨테이너 빌드 전용
│   ├── scripts/
│   │   ├── start.sh                 # 컨테이너 진입점
│   │   └── post_start.sh            # 시작 후 스크립트
│   ├── src/                         # 런타임 바이너리
│   │   ├── serve-remote.py
│   │   ├── start-vscode
│   │   ├── serve-local
│   │   ├── serve-remote
│   │   ├── init
│   │   └── vscode-server-setup.sh
│   └── proxy/                       # nginx 설정
│       ├── nginx.conf
│       └── readme.html
│
├── 🔧 dev-tools/                    # 개발/관리 도구
│   ├── check-dev-requirements.sh
│   ├── update-container-versions.py
│   ├── simple-version-test.sh
│   ├── test-version-integration.sh
│   └── README.md                    # 개발 도구 가이드
│
├── 📚 docs/                         # 문서 및 자료
│   ├── README.md                    # 메인 프로젝트 문서
│   ├── guides/
│   │   ├── development.md           # 개발 가이드
│   │   ├── tool-management.md       # 도구 관리 가이드
│   │   └── dev-requirements.md      # 개발 환경 요구사항
│   ├── migration/
│   │   ├── project-restructure.md   # 구조 재구성 문서
│   │   └── option1-plan.md          # 이 문서
│   └── assets/
│       └── logo/                    # 프로젝트 로고 및 이미지
│           └── runpod.txt
│
└── 🔧 빌드 설정 (루트)
    ├── Dockerfile                   # container/ 참조
    ├── docker-bake.hcl
    ├── .versions.env
    ├── setup_multi_architecture_build.sh
    ├── Makefile
    ├── pyproject.toml
    └── uv.lock
```

## 📋 단계별 마이그레이션 계획

### 1단계: 디렉토리 구조 생성 ✅

```bash
# 새 디렉토리 생성
mkdir -p container/scripts
mkdir -p container/src  
mkdir -p container/proxy
mkdir -p dev-tools
mkdir -p docs/guides
mkdir -p docs/migration
mkdir -p docs/assets/logo
```

### 2단계: 컨테이너 빌드 파일 이동

```bash
# 컨테이너 스크립트 이동
mv scripts/start.sh container/scripts/
mv scripts/post_start.sh container/scripts/

# 런타임 소스 이동
mv src/* container/src/

# 프록시 설정 이동
mv proxy/* container/proxy/
```

### 3단계: 개발 도구 이동

```bash
# 개발 도구 이동
mv scripts/check-dev-requirements.sh dev-tools/
mv scripts/update-container-versions.py dev-tools/
mv scripts/simple-version-test.sh dev-tools/
mv scripts/test-version-integration.sh dev-tools/
mv scripts/README.md dev-tools/
```

### 4단계: 문서 이동 및 정리

```bash
# 가이드 문서 이동
mv dev-requirements.md docs/guides/
mv TOOL_MANAGEMENT.md docs/guides/tool-management.md
mv DEVELOPMENT.md docs/guides/development.md

# 마이그레이션 문서 이동
mv PROJECT_RESTRUCTURE.md docs/migration/project-restructure.md
mv MIGRATION_PLAN_OPTION1.md docs/migration/option1-plan.md

# 자료 이동
mv logo/* docs/assets/logo/

# 메인 README는 docs/로 이동 후 루트에 간단한 버전 생성
cp README.md docs/README.md
```

### 5단계: Dockerfile 경로 업데이트

```dockerfile
# 기존
COPY scripts/post_start.sh /
COPY scripts/start.sh /
COPY src/* /usr/local/bin/
COPY proxy/nginx.conf /etc/nginx/nginx.conf
COPY proxy/readme.html /etc/nginx/html/

# 새로운 구조
COPY container/scripts/post_start.sh /
COPY container/scripts/start.sh /
COPY container/src/* /usr/local/bin/
COPY container/proxy/nginx.conf /etc/nginx/nginx.conf
COPY container/proxy/readme.html /etc/nginx/html/
```

### 6단계: 기타 파일 경로 업데이트

#### Makefile 업데이트
```makefile
# 기존 경로들을 새 경로로 변경
```

#### GitHub Actions 업데이트
```yaml
# .github/workflows/build-and-push.yml
# 필요한 경우 경로 업데이트
```

#### 개발 도구 스크립트 내부 경로 업데이트
```bash
# dev-tools/simple-version-test.sh 등에서
# 상대 경로 수정
```

### 7단계: 기존 디렉토리 정리

```bash
# 빈 디렉토리 제거
rmdir scripts src proxy logo

# .gitignore 업데이트 (필요한 경우)
```

## 🔄 마이그레이션 후 검증

### 빌드 테스트
```bash
# 문법 검사
docker buildx bake --print cpu

# 실제 빌드 테스트
docker buildx bake cpu

# 컨테이너 실행 테스트
docker run --rm -it [이미지명] /bin/bash
```

### 개발 도구 테스트
```bash
# 개발 환경 체크
./dev-tools/check-dev-requirements.sh

# 버전 테스트
./dev-tools/simple-version-test.sh

# 버전 관리 도구 테스트
python3 dev-tools/update-container-versions.py --check-latest
```

## 📊 예상 영향 범위

### ✅ 장점
- **완전한 관심사 분리**: 용도별로 명확히 구분
- **확장성**: 향후 새 컴포넌트 추가 시 명확한 위치
- **가독성**: 새 개발자도 구조를 쉽게 이해
- **유지보수성**: 각 영역별 독립적 관리 가능

### ⚠️ 단점
- **초기 작업량**: 모든 경로 업데이트 필요
- **학습 곡선**: 기존 개발자들의 적응 시간 필요
- **호환성**: 기존 스크립트/문서의 경로 수정 필요

## 🕐 예상 소요 시간

| 단계 | 예상 시간 | 난이도 |
|------|-----------|--------|
| 1-2단계: 디렉토리 생성 및 파일 이동 | 30분 | ⭐ |
| 3-4단계: 개발 도구 및 문서 이동 | 45분 | ⭐⭐ |
| 5단계: Dockerfile 수정 | 15분 | ⭐ |
| 6단계: 경로 업데이트 | 60분 | ⭐⭐⭐ |
| 7단계: 검증 및 테스트 | 30분 | ⭐⭐ |
| **총 예상 시간** | **3시간** | ⭐⭐ |

## 🚀 실행 준비

### 사전 조건
- [ ] 현재 작업 커밋 완료
- [ ] 백업 브랜치 생성
- [ ] 개발 환경 정상 동작 확인

### 롤백 계획
```bash
# 문제 발생 시 롤백
git checkout HEAD~1
# 또는 백업 브랜치로 복원
git checkout backup-before-migration
```

## 🎯 성공 기준

1. **빌드 성공**: `docker buildx bake cpu` 정상 실행
2. **컨테이너 실행**: 모든 서비스 정상 시작
3. **개발 도구 동작**: 모든 dev-tools 스크립트 정상 실행
4. **문서 접근성**: 새 구조로 문서 탐색 가능

---

**준비되면 1단계부터 시작합니다! 🚀** 