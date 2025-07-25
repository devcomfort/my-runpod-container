# 🐳 Personal RunPod Development Environment

> **완전히 새로워진 프로젝트 구조!** ✨  
> 컨테이너 빌드용 파일과 개발 도구가 명확히 분리되었습니다.

## 🎯 빠른 시작

```bash
# 1. 개발 환경 체크
./dev-tools/check-dev-requirements.sh

# 2. 빌드 설정 확인  
./dev-tools/simple-version-test.sh

# 3. 컨테이너 빌드
docker buildx bake cpu
```

## 📁 프로젝트 구조

```
personal-runpod-image/
├── 🐳 container/          # 컨테이너 빌드 전용
├── 🔧 dev-tools/         # 개발 및 관리 도구  
├── 📚 docs/              # 모든 문서 및 가이드
└── [빌드 설정 파일들]
```

## 📚 주요 문서

| 문서 | 설명 |
|------|------|
| [📖 **전체 가이드**](docs/README.md) | 상세한 프로젝트 문서 |
| [🔧 **개발 가이드**](docs/guides/development.md) | 개발 환경 설정 |
| [⚙️ **도구 관리**](docs/guides/tool-management.md) | 버전 관리 및 도구 분류 |
| [📋 **요구사항**](docs/guides/dev-requirements.md) | 개발 환경 요구사항 |

## 🚀 개발 워크플로우

### 🔍 환경 체크
```bash
./dev-tools/check-dev-requirements.sh
```

### 🔧 버전 관리
```bash
# 컨테이너 도구 버전 업데이트
python3 dev-tools/update-container-versions.py

# 버전 일관성 테스트
./dev-tools/simple-version-test.sh
```

### 🐳 빌드 및 실행
```bash
# CPU 버전 빌드
docker buildx bake cpu

# CUDA 12.6.2 버전 빌드  
docker buildx bake 12-6-2
```

## 📞 문의 및 지원

- **📖 문서**: [docs/](docs/) 디렉토리 참조
- **🔧 개발 도구**: [dev-tools/](dev-tools/) 디렉토리 참조
- **🐳 컨테이너**: [container/](container/) 디렉토리 참조

---

> **이전 README**: [docs/README.md](docs/README.md)에서 전체 내용 확인 가능 