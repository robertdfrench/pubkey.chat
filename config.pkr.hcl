packer {
 required_plugins {
    vultr = {
      version = ">= 2.4.5"
      source  = "github.com/vultr/vultr"
    }
  }
}

variable "vultr_api_key" {
  type    = string
  default = "${env("VULTR_API_KEY")}"
}

variable "vultr_os_id" {
  type    = number
}

variable "image_description" {
  type = string
}

variable "vultr_plan_id" {
  type = string
}

variable "vultr_region_id" {
  type = string
}

source "vultr" "image" {
  api_key              = var.vultr_api_key
  os_id                = var.vultr_os_id
  plan_id              = var.vultr_plan_id
  region_id            = var.vultr_region_id
  snapshot_description = var.image_description
  state_timeout        = "10m"
  ssh_username         = "root"
}

build {
  name = var.image_description
  sources = ["source.vultr.image"]

  provisioner "file" {
    source = "application/"
    destination = "/root"
  }

  provisioner "shell" {
    inline = ["make"]
  }
}
