# Create an S3 bucket
resource "aws_s3_bucket" "chat_service_bucket" {
  bucket        = "objects-dot-pubkey-dot-chat"
  force_destroy = true
}

output "bucket_name" {
  value = aws_s3_bucket.chat_service_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.chat_service_bucket.arn
}
