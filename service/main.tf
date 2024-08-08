data "aws_caller_identity" "current" {}

# Data source to get the latest Packer-built AMI
data "aws_ami" "packer_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["chat-service-*"]
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "chat_service_bucket" {
  bucket = "objects-dot-pubkey-dot-chat"
}

# Create an SQS queue
resource "aws_sqs_queue" "chat_service_queue" {
  name = "chat-service-queue"
}

# Create a security group for the EC2 instance
resource "aws_security_group" "chat_service_sg" {
  name_prefix = "chat-service-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance using the Packer AMI
resource "aws_instance" "chat_service_instance" {
  ami           = data.aws_ami.packer_ami.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.chat_service_sg.name]

  tags = {
    Name = "Chat Service Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "QUEUE_URL=https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.chat_service_queue.name}" >> /etc/environment
              echo "BUCKET_NAME=${aws_s3_bucket.chat_service_bucket.bucket}" >> /etc/environment
              EOF
}

# Output the SQS queue URL and S3 bucket name
output "sqs_queue_url" {
  value = aws_sqs_queue.chat_service_queue.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.chat_service_bucket.bucket
}

output "instance_id" {
  value = aws_instance.chat_service_instance.id
}
