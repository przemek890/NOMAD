variable "NOMAD_REF" {
  default = "v1.34.1"
}

variable "PLATFORM" {
  default = "linux/arm64"
}

variable "BOX_IMAGE" {
  default = "nomad-box:latest"
}

variable "UPSTREAM" {
  default = "https://github.com/crosstalk-solutions/project-nomad.git"
}

variable "IMAGES_DIR" {
  default = ".build/images"
}

variable "VENDOR_IMAGES" {
  default = {
    mysql = "mysql:8.0"
    redis = "redis:7-alpine"
    dozzle = "amir20/dozzle:v10.0"
  }
}

group "images" {
  targets = ["admin", "disk-collector", "vendor"]
}

group "default" {
  targets = ["box"]
}

target "_arm" {
  platforms = [PLATFORM]
}

target "admin" {
  inherits = ["_arm"]
  context = "${UPSTREAM}#${NOMAD_REF}"
  args = {
    VERSION = trimprefix(NOMAD_REF, "v")
  }
  tags = ["nomad-local/project-nomad:${NOMAD_REF}"]
  output = ["type=docker,dest=${IMAGES_DIR}/admin.tar"]
}

target "disk-collector" {
  inherits = ["_arm"]
  context = "${UPSTREAM}#${NOMAD_REF}:install/sidecar-disk-collector"
  tags = ["nomad-local/project-nomad-disk-collector:${NOMAD_REF}"]
  output = ["type=docker,dest=${IMAGES_DIR}/disk-collector.tar"]
}

target "vendor" {
  name = "vendor-${item}"
  matrix = {
    item = keys(VENDOR_IMAGES)
  }
  inherits = ["_arm"]
  dockerfile-inline = "FROM ${VENDOR_IMAGES[item]}"
  tags = [VENDOR_IMAGES[item]]
  output = ["type=docker,dest=${IMAGES_DIR}/${item}.tar"]
}

target "box" {
  inherits = ["_arm"]
  context = "."
  dockerfile = "box/Dockerfile"
  contexts = {
    images = IMAGES_DIR
  }
  args = {
    NOMAD_VERSION = NOMAD_REF
    NOMAD_ADMIN_IMAGE = "nomad-local/project-nomad:${NOMAD_REF}"
    NOMAD_DISK_COLLECTOR_IMAGE = "nomad-local/project-nomad-disk-collector:${NOMAD_REF}"
    NOMAD_MYSQL_IMAGE = VENDOR_IMAGES["mysql"]
    NOMAD_REDIS_IMAGE = VENDOR_IMAGES["redis"]
    NOMAD_DOZZLE_IMAGE = VENDOR_IMAGES["dozzle"]
  }
  tags = [BOX_IMAGE]
  output = ["type=docker"]
}
