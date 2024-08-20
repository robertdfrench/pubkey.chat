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

data "terraform_remote_state" "oob" {
  backend = "local"
  config = {
    path = "oob/terraform.tfstate"
  }
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
  name = "chat_service_policy"
  role = aws_iam_role.chat_service_role.id

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
          "${data.terraform_remote_state.oob.outputs.bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "${aws_dynamodb_table.locking_table.arn}"
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
  vpc_id      = data.aws_vpc.default.id # You'll need to create a VPC resource

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

# Output the SQS queue URL and S3 bucket name
output "sqs_queue_url" {
  value = aws_sqs_queue.chat_service_queue.id
}
