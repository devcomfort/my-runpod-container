#!/bin/bash

# Mock Commands for Testing
# 테스트용 외부 명령어 모킹 함수들

# Docker 명령어 모킹
mock_docker_success() {
    function docker() {
        case "$1" in
            "--version")
                echo "Docker version 24.0.1, build abc123"
                return 0
                ;;
            "buildx")
                case "$2" in
                    "version")
                        echo "github.com/docker/buildx v0.11.2 def456"
                        return 0
                        ;;
                    "create")
                        echo "Creating buildx instance..."
                        return 0
                        ;;
                    "ls")
                        echo "NAME/NODE       DRIVER/ENDPOINT STATUS  BUILDKIT PLATFORMS"
                        echo "multiarch*      docker-container"
                        echo "  multiarch0    unix:///var/run/docker.sock running v0.11.2  linux/amd64, linux/arm64"
                        return 0
                        ;;
                esac
                ;;
            "run")
                echo "Container running..."
                return 0
                ;;
            *)
                echo "Docker command executed: $*"
                return 0
                ;;
        esac
    }
    export -f docker
}

# Docker 명령어 실패 모킹
mock_docker_failure() {
    function docker() {
        case "$1" in
            "--version")
                echo "docker: command not found" >&2
                return 127
                ;;
            "buildx")
                echo "docker: 'buildx' is not a docker command" >&2
                return 1
                ;;
            *)
                echo "Docker daemon not running" >&2
                return 1
                ;;
        esac
    }
    export -f docker
}

# Git 명령어 모킹
mock_git_success() {
    function git() {
        case "$1" in
            "--version")
                echo "git version 2.34.1"
                return 0
                ;;
            *)
                echo "Git command executed: $*"
                return 0
                ;;
        esac
    }
    export -f git
}

# command 명령어 모킹 (성공)
mock_command_success() {
    function command() {
        case "$1" in
            "-v")
                case "$2" in
                    "docker"|"git"|"python3"|"uname")
                        echo "/usr/bin/$2"
                        return 0
                        ;;
                    *)
                        return 1
                        ;;
                esac
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f command
}

# command 명령어 모킹 (실패)
mock_command_failure() {
    function command() {
        return 1
    }
    export -f command
}

# uname 명령어 모킹
mock_uname_linux_x86() {
    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "Linux" ;;
            *) echo "Linux" ;;
        esac
        return 0
    }
    export -f uname
}

mock_uname_linux_arm() {
    function uname() {
        case "$1" in
            "-m") echo "aarch64" ;;
            "-s") echo "Linux" ;;
            *) echo "Linux" ;;
        esac
        return 0
    }
    export -f uname
}

mock_uname_macos() {
    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "Darwin" ;;
            *) echo "Darwin" ;;
        esac
        return 0
    }
    export -f uname
}

# service 명령어 모킹
mock_service_success() {
    function service() {
        echo "Service $1 $2: [OK]"
        return 0
    }
    export -f service
}

# ssh-keygen 명령어 모킹
mock_ssh_keygen_success() {
    function ssh-keygen() {
        case "$1" in
            "-lf")
                echo "2048 SHA256:abc123def456 test@example.com (RSA)"
                ;;
            "-t")
                echo "Generating public/private $2 key pair."
                echo "Your identification has been saved in $4"
                echo "Your public key has been saved in $4.pub"
                ;;
        esac
        return 0
    }
    export -f ssh-keygen
}

# chmod/mkdir 명령어 모킹
mock_file_operations() {
    function chmod() {
        echo "chmod $*" >/dev/null
        return 0
    }
    function mkdir() {
        # 실제로는 TEST_TMP_DIR 하위에만 생성
        case "$1" in
            "-p")
                shift
                echo "mkdir -p $*" >/dev/null
                ;;
            *)
                echo "mkdir $*" >/dev/null
                ;;
        esac
        return 0
    }
    export -f chmod mkdir
}

# 모든 성공 모킹 활성화
enable_all_success_mocks() {
    mock_docker_success
    mock_git_success
    mock_command_success
    mock_uname_linux_x86
    mock_service_success
    mock_ssh_keygen_success
    mock_file_operations
}

# 모든 실패 모킹 활성화
enable_all_failure_mocks() {
    mock_docker_failure
    mock_command_failure
}

# 특정 도구만 실패하도록 모킹
mock_missing_tool() {
    local tool="$1"
    
    function command() {
        case "$1" in
            "-v")
                case "$2" in
                    "$tool")
                        return 1
                        ;;
                    *)
                        echo "/usr/bin/$2"
                        return 0
                        ;;
                esac
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f command
    
    # 도구별 직접 호출도 실패하도록
    function "$tool"() {
        echo "$tool: command not found" >&2
        return 127
    }
    export -f "$tool"
} 