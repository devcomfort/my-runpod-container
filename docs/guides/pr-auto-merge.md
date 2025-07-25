# 🚀 Dev 브랜치 자동 빌드 & Main 머지 시스템

## 📋 개요

이 프로젝트는 **dev 브랜치 중심의 CI/CD 파이프라인**을 도입했습니다. dev 브랜치에서 모든 개발이 진행되고, 빌드와 테스트가 성공하면 **자동으로 main 브랜치에 머지**됩니다.

> **🎯 핵심 철학**: `dev` = 활발한 개발, `main` = 안정된 아카이브

## 🔄 새로운 자동화 워크플로우

### **🚀 Dev 브랜치 워크플로우**

```mermaid
graph LR
    A[dev 브랜치 push] --> B[🧪 Shell Tests]
    A --> C[🐳 Docker Build]
    B --> D{모든 체크 성공?}
    C --> D
    D -->|✅ 성공| E[🤖 main PR 자동 생성]
    D -->|❌ 실패| F[🚫 머지 중단]
    E --> G[✅ 자동 승인]
    G --> H[🔄 main 머지]
    H --> I[📚 main 아카이브 완료]
```

### **트리거 조건**
- ✅ **dev 브랜치 push**: 즉시 빌드 및 테스트 시작
- ✅ **모든 체크 성공**: 자동으로 main 브랜치 머지 프로세스 시작

### **필수 체크 항목**
1. **🧪 Shell 테스트**: Unit, Mocked, Integration 테스트 (73개)
2. **🐳 Docker 빌드**: 멀티 아키텍처 빌드 성공

## 🎯 완전 자동화 프로세스

### **1단계: dev 브랜치 개발** 
```bash
# 일상적인 개발 워크플로우
git checkout dev
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin dev
# 🚀 이제 모든 것이 자동으로 시작됩니다!
```

### **2단계: 자동 빌드 & 테스트**
```yaml
⚡ 즉시 실행 (병렬):
  🧪 Shell Tests (Unit/Mocked/Integration)
  🐳 Docker Build (모든 타겟, 멀티 아키텍처)
```

### **3단계: 성공 시 자동 main 머지**
```yaml
✅ 모든 체크 통과 시:
  🤖 main 브랜치에 PR 자동 생성
  ✅ 자동 승인
  🔄 Squash merge로 머지
  📚 main 브랜치 아카이브 업데이트
```

## 📊 워크플로우 상세

### **🔍 필수 체크 요구사항**

| 워크플로우 | 실행 조건 | 필수 여부 | 실패 시 처리 |
|-----------|-----------|----------|------------|
| 🧪 **Shell Tests** | dev push | ✅ 필수 | 머지 중단 |
| 🐳 **Build and Push** | dev push | ✅ 필수 | 머지 중단 |

### **🚀 자동 처리 프로세스**

#### **✅ 성공적인 자동 머지 흐름**
```bash
# dev 브랜치에서 개발
git push origin dev

# 자동 실행
✅ Shell 테스트 통과 (73개 케이스)
✅ Docker 빌드 성공 (CPU/CUDA 모든 타겟)

# 자동 main 머지
🤖 "🚀 Auto-merge: [커밋 메시지]" PR 생성
✅ 자동 승인 및 머지
📚 main 브랜치 업데이트 완료

# 결과
🎉 코드가 안전하게 main에 아카이브됨!
```

#### **❌ 실패 시 처리**
```bash
# dev 브랜치에서 push
git push origin dev

# 일부 체크 실패
❌ Shell 테스트 실패 또는
❌ Docker 빌드 실패

# 결과
🚫 main 머지 하지 않음
📝 GitHub Actions에서 실패 로그 확인 가능
🔧 문제 수정 후 다시 push하면 재시도
```

## 🛠️ 개발자 워크플로우

### **일상적인 개발 과정**

```bash
# 1. dev 브랜치에서 개발
git checkout dev
git pull origin dev  # 최신 상태로 동기화

# 2. 기능 개발 및 로컬 테스트
just dev-setup      # 개발 환경 설정
just test           # 로컬 테스트 실행
just cpu            # 로컬 빌드 테스트

# 3. 커밋 및 푸시 (자동화 시작점)
git add .
git commit -m "feat: 새로운 기능 구현"
git push origin dev  # 🚀 여기서 모든 자동화 시작!

# 4. 결과 확인
# GitHub Actions에서 진행 상황 모니터링
# 성공 시: main 브랜치에 자동 머지됨 ✅
# 실패 시: 로그 확인 후 수정 🔧
```

### **브랜치 전략**

#### **🔄 단순화된 Git 플로우**
```bash
# 주요 브랜치
main    # 📚 안정된 아카이브 (읽기 전용)
dev     # 🚀 활발한 개발 (주 작업 브랜치)

# 개발 브랜치 (필요시)
feature/new-feature  # dev에서 분기 → dev로 머지
bugfix/critical-fix  # dev에서 분기 → dev로 머지
```

#### **⚠️ 중요한 변경사항**
```bash
# ❌ 더 이상 이렇게 하지 않음
git checkout -b feature/branch
# PR을 main에 생성

# ✅ 새로운 방식
git checkout dev
# 직접 dev에서 개발하거나
git checkout -b feature/branch
# dev로 머지 후 자동으로 main에 반영
```

## 📈 장점 및 개선사항

### **✅ 새로운 시스템의 장점**

| 항목 | 기존 방식 | 새로운 방식 | 개선 효과 |
|------|-----------|-------------|-----------|
| **브랜치 관리** | main PR 관리 | dev 중심 개발 | 🎯 단순화 |
| **머지 프로세스** | 수동 PR 승인 | 완전 자동화 | ⚡ 빠른 배포 |
| **안정성** | 수동 확인 의존 | 엄격한 자동 검증 | 🛡️ 높은 신뢰성 |
| **아카이빙** | 관리 부담 | 자동 main 업데이트 | 📚 일관된 기록 |

### **🔧 개발자 경험 개선**
- **단순한 워크플로우**: dev 브랜치에서만 작업
- **즉시 피드백**: push 후 바로 테스트 결과 확인
- **자동 배포**: 성공 시 추가 작업 없이 main 반영
- **안전한 개발**: 실패 시 main에 영향 없음

## ⚙️ 고급 설정 및 커스터마이징

### **워크플로우 모니터링**

```bash
# GitHub Actions 상태 확인
https://github.com/your-repo/actions

# 실시간 로그 확인
gh run list --branch dev
gh run view <run-id> --log
```

### **긴급 상황 대응**

#### **수동 main 머지** (비상시)
```bash
# GitHub CLI 사용
gh pr create --base main --head dev --title "Emergency merge"
gh pr merge --squash

# 또는 GitHub 웹에서 수동 처리
```

#### **자동 머지 일시 중지**
- 현재는 dev 브랜치 push를 중단하는 것이 유일한 방법
- 향후 `[skip-ci]` 태그 지원 예정

### **디버깅 및 문제 해결**

#### **일반적인 실패 시나리오**

```bash
# 1. Shell 테스트 실패
just test-all              # 로컬에서 재현
just test-unit             # 단위 테스트만
just test-integration      # 통합 테스트만

# 2. Docker 빌드 실패
just check-env             # 환경 설정 확인
just cpu                   # 로컬 빌드 테스트
./dev-tools/simple-version-test.sh  # 버전 일관성 확인

# 3. 워크플로우 자체 오류
# GitHub Actions 로그에서 상세 정보 확인
```

## 🎯 향후 개선 계획

### **단기 계획** (1-2개월)
- [ ] `[skip-ci]` 커밋 메시지 태그 지원
- [ ] 실패 시 Slack/Discord 알림
- [ ] 더 상세한 빌드 리포트

### **장기 계획** (3-6개월)
- [ ] 스테이징 환경 자동 배포
- [ ] 성능 벤치마크 자동 실행
- [ ] 릴리즈 노트 자동 생성

---

## 🚀 결론

새로운 **dev 브랜치 중심 CI/CD 시스템**으로 개발 프로세스가 크게 단순화되었습니다:

1. **dev에서 개발** → 2. **자동 테스트/빌드** → 3. **자동 main 머지**

이제 개발자는 `dev` 브랜치에서만 작업하고, 나머지는 모두 자동화되어 **더 빠르고 안전한 개발**이 가능합니다! 🎉 