# 🤖 PR 자동 머지 시스템 가이드

## 📋 개요

이 프로젝트는 **빌드가 성공적으로 완료된 경우에만 main 브랜치로 자동 머지**되는 시스템을 도입했습니다. 모든 테스트와 빌드가 통과해야만 코드가 main 브랜치에 반영됩니다.

## 🔄 자동 머지 워크플로우

### **트리거 조건**
- PR이 생성, 업데이트, 또는 ready for review 상태가 될 때
- 빌드 또는 테스트 워크플로우가 완료될 때

### **필수 체크 항목**
1. **🐳 Docker 빌드**: 모든 타겟의 빌드가 성공적으로 완료
2. **🧪 Shell 테스트**: Unit, Mocked, Integration 테스트 모두 통과
3. **📋 PR 상태**: Draft가 아니고 충돌이 없어야 함

## 🎯 자동 머지 프로세스

### **1단계: PR 자격 요건 확인**
```yaml
✅ Draft PR이 아님
✅ 충돌이 없음 (mergeable 상태)
✅ main 브랜치 대상 PR
```

### **2단계: 모든 체크 완료 대기**
```yaml
⏳ 최대 30분 대기
🔍 30초 간격으로 상태 확인
✅ 모든 필수 워크플로우 성공 확인
```

### **3단계: 자동 승인 및 머지**
```yaml
✅ PR 자동 승인
🔄 Squash merge로 머지
🗑️ 브랜치 자동 삭제
```

## 📊 워크플로우 상세

### **🔍 체크 요구사항**

| 워크플로우 | 설명 | 필수 여부 |
|-----------|------|----------|
| 🐳 **Build and Push** | Docker 멀티 아키텍처 빌드 | ✅ 필수 |
| 🧪 **Shell Tests** | Shell 스크립트 테스트 (73개) | ✅ 필수 |

### **🤖 자동 처리 상황**

#### **✅ 자동 머지되는 경우**
```bash
# 모든 조건을 만족할 때
✅ Shell 테스트 통과 (unit/mocked/integration)
✅ Docker 빌드 성공 (모든 타겟)
✅ PR 상태 정상 (draft 아님, 충돌 없음)
→ 🎉 자동으로 main에 머지됨
```

#### **❌ 자동 머지되지 않는 경우**
```bash
# 다음 중 하나라도 해당할 때
❌ 테스트 실패 또는 빌드 실패
❌ Draft PR 상태
❌ 충돌(conflict) 존재
❌ 30분 내 체크 완료되지 않음
→ 💬 실패 사유를 PR에 코멘트로 안내
```

## 🛠️ 개발자 워크플로우

### **일반적인 PR 생성 과정**

```bash
# 1. 기능 브랜치 생성
git checkout -b feature/new-feature

# 2. 개발 및 테스트
just dev-setup
just test
just cpu  # 로컬 빌드 테스트

# 3. 커밋 및 푸시
git add .
git commit -m "feat: new feature"
git push origin feature/new-feature

# 4. PR 생성 (GitHub 웹에서)
# → 자동으로 빌드 및 테스트 시작

# 5. 모든 체크 통과 시
# → 🤖 자동으로 승인 및 머지됨!
```

### **문제 해결 시나리오**

#### **테스트 실패 시**
```bash
# 실패한 테스트 로컬에서 재현
just test-all

# 문제 수정 후 다시 푸시
git add .
git commit -m "fix: resolve test failures"
git push origin feature/new-feature
# → 자동으로 재검사 시작
```

#### **빌드 실패 시**
```bash
# 로컬에서 빌드 테스트
just build-test

# Docker 설정 문제 확인
just check-env
just check-versions

# 수정 후 다시 푸시
git push origin feature/new-feature
```

## ⚙️ 고급 설정

### **Manual Override 옵션**

급한 상황에서는 수동으로 머지할 수 있습니다:

```bash
# GitHub CLI 사용
gh pr merge <PR번호> --squash

# 또는 GitHub 웹에서
# 1. PR 페이지에서 "Merge pull request" 클릭
# 2. "Squash and merge" 선택
```

### **자동 머지 일시 중지**

특정 PR에서 자동 머지를 방지하려면:

1. **Draft로 변경**: PR을 Draft 상태로 변경
2. **[skip-automerge] 태그**: 커밋 메시지에 포함 (향후 구현 예정)

## 🔧 워크플로우 커스터마이징

### **타임아웃 조정**

```yaml
# .github/workflows/pr-auto-merge.yml에서
MAX_WAIT=1800  # 30분 (기본값)
WAIT_INTERVAL=30  # 30초 간격
```

### **필수 체크 추가**

```yaml
# 새로운 워크플로우 추가 시
REQUIRED_CHECKS=("워크플로우1" "워크플로우2" "새워크플로우")
```

## 📈 모니터링 및 분석

### **GitHub Actions 요약에서 확인**

각 PR에서 자동 머지 상태를 실시간으로 확인할 수 있습니다:

- **✅ 자동 머지 성공**: 모든 체크 통과하여 머지 완료
- **❌ 자동 머지 실패**: 실패 사유와 해결 방법 제공
- **⏳ 체크 진행 중**: 현재 진행 중인 체크 상태 표시

### **알림 설정**

GitHub 알림에서 다음을 확인할 수 있습니다:

- PR 자동 승인 알림
- 머지 완료 알림  
- 실패 시 코멘트 알림

## 🚨 트러블슈팅

### **자주 발생하는 문제**

#### **체크가 무한 대기 상태**
```bash
# 원인: 워크플로우 이름 불일치
# 해결: REQUIRED_CHECKS 배열의 이름 확인

# 확인 방법
gh api repos/:owner/:repo/actions/workflows
```

#### **권한 부족 오류**
```bash
# 필요한 권한:
# - contents: write
# - pull-requests: write
# - checks: read
# - actions: read
```

#### **머지 후에도 브랜치가 남아있음**
```bash
# 원인: 브랜치 보호 규칙
# 해결: GitHub 설정에서 "Automatically delete head branches" 활성화
```

## 📚 관련 문서

- [GitHub Actions 워크플로우](../workflows/)
- [Shell 테스트 시스템](../shell-testing.md)
- [Just 명령 실행기](just-usage.md)
- [개발 가이드](development.md)

## 🔗 유용한 링크

- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Auto-merge 설정](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request) 