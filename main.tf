terraform {
  cloud {
    organization = "robertdfrench"

    workspaces {
      name = "pubkey_chat"
    }
  }
}

resource "null_resource" "example" {
  triggers = {
    value = "A example resource that does nothing!"
  }
}
