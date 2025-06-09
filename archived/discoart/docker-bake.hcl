variable "RELEASE" {
  default = "0.0.0"
}

variable "GITHUB_WORKSPACE" {
  default = "."
}

target "default" {
  context = "${GITHUB_WORKSPACE}/official-templates/discoart"
  dockerfile = "Dockerfile"
  tags = ["runpod/discoart:${RELEASE}"]
  contexts = {
    scripts = "container-template"
    proxy = "container-template/proxy"
  }
}
