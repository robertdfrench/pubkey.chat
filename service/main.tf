data "aws_region" "current" {}

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

# Create IAM role
resource "aws_iam_role" "chat_service_role" {
  name = "chat_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policy to IAM role
resource "aws_iam_role_policy" "chat_service_policy" {
  name   = "chat_service_policy"
  role   = aws_iam_role.chat_service_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.chat_service_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = "${aws_sqs_queue.chat_service_queue.arn}"
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "chat_service_instance_profile" {
  name = "chat_service_instance_profile"
  role = aws_iam_role.chat_service_role.name
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
  iam_instance_profile = aws_iam_instance_profile.chat_service_instance_profile.name

  tags = {
    Name = "Chat Service Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "[DEFAULT]" > /etc/chat.ini
              echo "queue_url=${aws_sqs_queue.chat_service_queue.name}" >> /etc/chat.ini
              echo "bucket_name=${aws_s3_bucket.chat_service_bucket.bucket}" >> /etc/chat.ini
              echo "region=${data.aws_region.current.name}" >> /etc/chat.ini
              systemctl enable chat.service
              systemctl start chat.service
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
