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

resource "vultr_instance" "atl" {
  plan        = "vhp-1c-1gb-intel"
  region      = "atl"
  snapshot_id = "c64844c8-862d-4b75-88e1-62d8d2e5c6a8"
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

resource "vultr_ssh_key" "root" {
  name    = "root"
  ssh_key = file("deploy_key.pub")
}
