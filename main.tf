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

resource "vultr_dns_record" "www" {
  domain = vultr_dns_domain.root.id
  name   = "www"
  data   = "149.28.43.177"
  type   = "A"
}
