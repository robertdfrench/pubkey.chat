terraform {
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
