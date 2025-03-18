# 변수 정의
variable "RELEASE" {
  default = "0.2"
}

variable "DOCKER_HUB_USERNAME" {
  default = "devcomfort"
}

group "default" {
  targets = ["cpu", "11-1-1", "11-8-0", "12-1-0", "12-2-0", "12-4-1", "12-5-1", "12-6-2"]
}

target "cpu" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cpu"]
    platforms = ["linux/amd64", "linux/arm64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "ubuntu:20.04"
    }
}

target "11-1-1" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.1.1"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:11.1.1-devel-ubuntu20.04"
    }
}

target "11-8-0" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda11.8.0"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:11.8.0-devel-ubuntu22.04"
    }
}

target "12-1-0" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.1.0"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.1.0-devel-ubuntu22.04"
    }
}

target "12-2-0" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.2.0"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.2.0-devel-ubuntu22.04"
    }
}

target "12-4-1" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.4.1"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.4.1-devel-ubuntu22.04"
    }
}

target "12-5-1" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.5.1"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.5.1-devel-ubuntu22.04"
    }
}

target "12-6-2" {
    dockerfile = "Dockerfile"
    tags = ["${DOCKER_HUB_USERNAME}/personal-runpod-environment:${RELEASE}-cuda12.6.2"]
    platforms = ["linux/amd64"]
    contexts = {
        scripts = "./scripts"
        proxy = "./proxy"
        logo = "./logo"
    }
    args = {
        BASE_RELEASE_VERSION = "${RELEASE}"
        BASE_IMAGE = "nvidia/cuda:12.6.2-devel-ubuntu22.04"
    }
}