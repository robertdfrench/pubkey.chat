resource "aws_dynamodb_table" "locking_table" {
  name           = "locking-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToLive"
    enabled        = true
  }

  tags = {
    Name        = "Chat Service Locking Table"
    Environment = "Production"
  }
}

output "locking_table" {
  value = aws_dynamodb_table.locking_table.name
}
