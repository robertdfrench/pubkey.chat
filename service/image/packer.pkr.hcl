packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "ami_name" {
  type = string
}

locals {
  instance_type = "t2.micro"
  ssh_username  = "ec2-user"
}

source "amazon-ebs" "us-east-1" {
  region        = "us-east-1"
  source_ami    = "ami-0427090fd1714168b" 

  instance_type = local.instance_type
  ssh_username  = local.ssh_username
  ami_name      = var.ami_name
}

build {
  sources = [
    "source.amazon-ebs.us-east-1",
  ]

  provisioner "file" {
    source = "chat.service"
    destination = "chat.service"
  }

  provisioner "file" {
    source = "service.py"
    destination = "service.py"
  }

  provisioner "shell" {
    script = "provisioner.sh"
  }

  post-processor "manifest" {
    output      = "build/manifest.json"
    strip_path  = true
  }
}
