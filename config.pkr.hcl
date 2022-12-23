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

source "vultr" "openbsd-72" {
  api_key              = "${var.vultr_api_key}"
  os_id                = var.vultr_os_id
  plan_id              = "vhf-1c-1gb"
  region_id            = "atl"
  snapshot_description = "pubkey.chat"
  state_timeout        = "10m"
  ssh_username         = "root"
}

build {
  name = "pubkey.chat"
  sources = ["source.vultr.openbsd-72"]

  provisioner "file" {
    source = "application/"
    destination = "/root"
  }

  provisioner "shell" {
    inline = ["make"]
  }
}
