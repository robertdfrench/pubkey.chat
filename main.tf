terraform {
  cloud {
    organization = "robertdfrench"

    workspaces {
      name = "pubkey_chat"
    }
  }
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.12.0"
    }
  }
}

variable "vultr_api_key" {
  type = string
}

provider "vultr" {
  api_key = var.vultr_api_key
}

resource "null_resource" "example" {
  triggers = {
    value = "A example resource that does nothing!"
  }
}

resource "vultr_dns_domain" "root" {
  domain = "pubkey.chat"
}

data "vultr_os" "openbsd" {
  filter {
    name   = "name"
    values = ["OpenBSD 7.2 x64"]
  }
}

resource "vultr_instance" "atl" {
  plan        = "vhp-1c-1gb-intel"
  region      = "atl"
  os_id       = data.vultr_os.openbsd.id
  label       = "atl"
  tags        = ["infrastructure"]
  hostname    = "atl.pubkey.chat"
  enable_ipv6 = true
}

resource "vultr_dns_record" "www" {
  domain = vultr_dns_domain.root.id
  name   = "www"
  data   = vultr_instance.atl.main_ip
  type   = "A"
}
