resource "aws_route53_zone" "main" {
  name = "pubkey.chat"
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "domain_name" {
  value = aws_route53_zone.main.name
}
