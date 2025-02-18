# Personal RunPod Environment

이 프로젝트는 RunPod를 위한 개인 환경을 구성하기 위한 Docker 이미지를 제공합니다. 필요한 경우 베이스 이미지를 변경할 수 있습니다.

## 빌드 명령

이미지를 빌드하려면 아래 명령어를 사용하세요. 기본적으로 Ubuntu 22.04를 베이스 이미지로 설정합니다.

```bash
docker build -t devcomfort/personal-runpod-environment:0.2 . --build-arg BASE_IMAGE=ubuntu:22.04
```

## 푸시 명령

이미지를 Docker Hub에 푸시하려면 아래 명령어를 사용하세요.

```bash
docker push devcomfort/personal-runpod-environment:0.2
```

## NOTE

- `htop` 패키지를 설치할 수 없어서 apt 미러 주소를 카카오로 변경하였습니다.