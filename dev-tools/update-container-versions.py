#!/usr/bin/env python3
"""
컨테이너 도구 버전 동기화 관리 스크립트
.versions.env를 기준으로 컨테이너 내부 도구들의 버전 정보를 동기화합니다.

주의: 개발자 로컬 도구(Docker, Buildx, Git 등)는 이 스크립트로 관리하지 않습니다.
"""

import os
import re
import sys
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import subprocess

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ContainerVersionManager:
    """컨테이너 도구 버전 관리 클래스 (개발자 로컬 도구 제외)"""
    
    def __init__(self, project_root: Optional[Path] = None):
        self.project_root = project_root or Path(__file__).parent.parent
        self.versions_file = self.project_root.parent / ".versions.env"
        self.versions = {}
        
    def load_versions(self) -> Dict[str, str]:
        """.versions.env에서 컨테이너 도구 버전 정보 로드"""
        if not self.versions_file.exists():
            raise FileNotFoundError(f".versions.env 파일을 찾을 수 없습니다: {self.versions_file}")
            
        logger.info(f"컨테이너 도구 버전 파일 로드중: {self.versions_file}")
        
        with open(self.versions_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    try:
                        key, value = line.split('=', 1)
                        # 따옴표 제거
                        value = value.strip('"\'')
                        self.versions[key.strip()] = value
                    except ValueError:
                        logger.warning(f"라인 {line_num}을 파싱할 수 없습니다: {line}")
        
        logger.info(f"로드된 컨테이너 도구 버전들: {self.versions}")
        return self.versions
    
    def update_dockerfile(self) -> bool:
        """Dockerfile의 ARG 버전들 업데이트 (컨테이너 도구만)"""
        dockerfile_path = self.project_root.parent / "Dockerfile"
        if not dockerfile_path.exists():
            logger.error("Dockerfile을 찾을 수 없습니다")
            return False
            
        logger.info("Dockerfile 컨테이너 도구 버전 업데이트 중...")
        
        with open(dockerfile_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        updated = False
        
        # 컨테이너 도구 ARG 패턴 매칭 및 업데이트
        container_arg_patterns = {
            'GO_VERSION': r'ARG GO_VERSION="([^"]*)"',
            'TINYGO_VERSION': r'ARG TINYGO_VERSION="([^"]*)"',
            'GH_VERSION': r'ARG GH_VERSION="([^"]*)"',
            'VS_CODE_VERSION': r'ARG VS_CODE_VERSION="([^"]*)"'
        }
        
        for version_key, pattern in container_arg_patterns.items():
            if version_key in self.versions:
                new_version = self.versions[version_key]
                new_arg = f'ARG {version_key}="{new_version}"'
                
                match = re.search(pattern, content)
                if match:
                    old_version = match.group(1)
                    if old_version != new_version:
                        content = re.sub(pattern, new_arg, content)
                        logger.info(f"✅ {version_key}: {old_version} → {new_version}")
                        updated = True
                    else:
                        logger.info(f"ℹ️  {version_key}: 이미 최신 버전 ({new_version})")
        
        if updated:
            with open(dockerfile_path, 'w', encoding='utf-8') as f:
                f.write(content)
            logger.info("✅ Dockerfile 컨테이너 도구 업데이트 완료")
        
        return updated
    
    def check_latest_versions(self) -> Dict[str, Tuple[str, str]]:
        """최신 버전 확인 (컨테이너 도구만, GitHub API 활용)"""
        logger.info("컨테이너 도구 최신 버전 확인 중...")
        
        # GitHub 릴리스 체크를 위한 저장소 매핑 (컨테이너 도구만)
        container_repos = {
            'GO_VERSION': None,  # Go는 특별 처리 필요
            'GH_VERSION': 'cli/cli',
            'TINYGO_VERSION': 'tinygo-org/tinygo'
        }
        
        results = {}
        
        for version_key, repo in container_repos.items():
            current_version = self.versions.get(version_key, 'unknown')
            
            if repo:
                try:
                    # GitHub API를 통한 최신 릴리스 확인
                    cmd = ['gh', 'api', f'repos/{repo}/releases/latest', '--jq', '.tag_name']
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
                    
                    if result.returncode == 0:
                        latest_version = result.stdout.strip()
                        # v 접두사 정규화
                        if latest_version.startswith('v'):
                            latest_version = latest_version[1:]
                        
                        results[version_key] = (current_version, latest_version)
                        
                        if current_version != latest_version:
                            logger.warning(f"🔄 {version_key}: {current_version} → {latest_version} (업데이트 가능)")
                        else:
                            logger.info(f"✅ {version_key}: {current_version} (최신)")
                    else:
                        logger.error(f"❌ {version_key}: 최신 버전 확인 실패")
                        results[version_key] = (current_version, 'unknown')
                        
                except (subprocess.TimeoutExpired, FileNotFoundError) as e:
                    logger.error(f"❌ {version_key}: GitHub CLI 오류 - {e}")
                    results[version_key] = (current_version, 'unknown')
            else:
                # Go는 웹 스크래핑이나 다른 방법 필요 (일단 스킵)
                results[version_key] = (current_version, 'check manually')
        
        return results
    
    def generate_report(self) -> str:
        """컨테이너 도구 버전 상태 보고서 생성"""
        logger.info("컨테이너 도구 버전 상태 보고서 생성 중...")
        
        report = []
        report.append("# 🐳 컨테이너 도구 버전 상태 보고서")
        report.append(f"생성일시: {subprocess.run(['date'], capture_output=True, text=True).stdout.strip()}")
        report.append("")
        report.append("⚠️  참고: 개발자 로컬 도구(Docker, Buildx, Git)는 별도 관리됩니다.")
        report.append("")
        
        # 현재 버전들
        report.append("## 📋 현재 설정된 컨테이너 도구 버전들")
        report.append("| 도구 | 현재 버전 | 파일 위치 |")
        report.append("|------|-----------|-----------|")
        
        container_file_locations = {
            'GO_VERSION': 'Dockerfile, docker-bake.hcl',
            'TINYGO_VERSION': 'Dockerfile, docker-bake.hcl',
            'GH_VERSION': 'Dockerfile, docker-bake.hcl',
            'VS_CODE_VERSION': 'Dockerfile'
        }
        
        for key, version in self.versions.items():
            if key in container_file_locations:  # 컨테이너 도구만 표시
                location = container_file_locations.get(key, '알 수 없음')
                report.append(f"| {key} | `{version}` | {location} |")
        
        report.append("")
        
        # 최신 버전 확인 결과
        latest_versions = self.check_latest_versions()
        report.append("## 🆕 최신 버전 비교 (컨테이너 도구)")
        report.append("| 도구 | 현재 버전 | 최신 버전 | 상태 |")
        report.append("|------|-----------|-----------|------|")
        
        for key, (current, latest) in latest_versions.items():
            if latest == 'unknown':
                status = "❓ 확인 필요"
            elif latest == 'check manually':
                status = "🔍 수동 확인"
            elif current == latest:
                status = "✅ 최신"
            else:
                status = "🔄 업데이트 가능"
                
            report.append(f"| {key} | `{current}` | `{latest}` | {status} |")
        
        return "\n".join(report)
    
    def sync_all(self, dry_run: bool = False) -> bool:
        """모든 파일의 컨테이너 도구 버전 동기화"""
        logger.info(f"컨테이너 도구 버전 동기화 시작 {'(시뮬레이션 모드)' if dry_run else ''}")
        
        try:
            self.load_versions()
            
            if dry_run:
                logger.info("🔍 변경사항 미리보기:")
                report = self.generate_report()
                print("\n" + report)
                return True
            
            updated_files = []
            
            if self.update_dockerfile():
                updated_files.append("Dockerfile")
            
            if updated_files:
                logger.info(f"✅ 업데이트된 파일들: {', '.join(updated_files)}")
                return True
            else:
                logger.info("ℹ️  모든 컨테이너 도구가 이미 최신 상태입니다")
                return True
                
        except Exception as e:
            logger.error(f"❌ 동기화 실패: {e}")
            return False

def main():
    """메인 실행 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(description="컨테이너 도구 버전 동기화 도구")
    parser.add_argument("--dry-run", action="store_true", 
                       help="실제 변경 없이 미리보기만 표시")
    parser.add_argument("--report", action="store_true", 
                       help="컨테이너 도구 버전 상태 보고서만 생성")
    parser.add_argument("--check-latest", action="store_true", 
                       help="최신 버전과 비교")
    
    args = parser.parse_args()
    
    try:
        manager = ContainerVersionManager()
        
        if args.report or args.check_latest:
            manager.load_versions()
            report = manager.generate_report()
            print(report)
        else:
            success = manager.sync_all(dry_run=args.dry_run)
            sys.exit(0 if success else 1)
            
    except KeyboardInterrupt:
        logger.info("사용자에 의해 중단됨")
        sys.exit(1)
    except Exception as e:
        logger.error(f"예상치 못한 오류: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 