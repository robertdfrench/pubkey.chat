variable "image_description" {
  type = string
}

resource "vultr_dns_domain" "root" {
  domain = "pubkey.chat"
}

variable "vultr_plan_id" {
  type = string
}

data "vultr_snapshot" "image" {
  filter {
    name = "description"
    values = [var.image_description]
  }
}

resource "vultr_instance" "regional" {
  for_each    = toset( ["atl", "ewr", "sjc", "mex"] )
  plan        = var.vultr_plan_id
  region      = each.key
  snapshot_id = data.vultr_snapshot.image.id
  label       = "${each.key}.infra.pubkey.chat"
  tags        = ["infrastructure"]
  hostname    = "${each.key}.infra.pubkey.chat"
  enable_ipv6 = true
}

resource "vultr_dns_record" "www" {
  for_each = vultr_instance.regional
  domain   = vultr_dns_domain.root.id
  name     = join(".", [split(".", each.value.hostname)[0], "infra"])
  data     = each.value.main_ip
  type     = "A"
}

resource "vultr_dns_record" "actual_www" {
  for_each = vultr_instance.regional
  domain   = vultr_dns_domain.root.id
  name     = "www"
  data     = each.value.main_ip
  type     = "A"
}
