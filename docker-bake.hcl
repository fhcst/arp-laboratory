variable "IMAGE_PREFIX" {
  default = "ghcr.io/fhcst/arp-laboratory"
}
variable "IMAGE_TAG" {
  default = "latest"
}
variable "SOURCE_REVISION" {
  default = "local"
}
variable "PLATFORMS" {
  default = "linux/amd64,linux/arm64"
}

group "default" {
  targets = ["router", "access", "server", "victim", "attack"]
}

target "_common" {
  platforms = split(",", PLATFORMS)
  labels = {
    "org.opencontainers.image.source" = "https://github.com/fhcst/arp-laboratory"
    "org.opencontainers.image.revision" = SOURCE_REVISION
    "org.opencontainers.image.licenses" = "MIT"
  }
}
target "router" {
  inherits = ["_common"]
  context = "./containers/router"
  tags = ["${IMAGE_PREFIX}-router:${IMAGE_TAG}"]
}
target "access" {
  inherits = ["_common"]
  context = "./containers/access"
  tags = ["${IMAGE_PREFIX}-access:${IMAGE_TAG}"]
}
target "server" {
  inherits = ["_common"]
  context = "./containers/server"
  tags = ["${IMAGE_PREFIX}-server:${IMAGE_TAG}"]
}
target "victim" {
  inherits = ["_common"]
  context = "./containers/victim"
  tags = ["${IMAGE_PREFIX}-victim:${IMAGE_TAG}"]
}
target "attack" {
  inherits = ["_common"]
  context = "./containers/attack"
  tags = ["${IMAGE_PREFIX}-attack:${IMAGE_TAG}"]
}
