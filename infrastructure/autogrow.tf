resource "aws_launch_template" "chat_service" {
  name_prefix   = "chat-service-"
  image_id      = data.aws_ami.packer_ami.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.chat_service_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.chat_service_instance_profile.name
  }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo "[DEFAULT]" > /etc/chat.ini
      echo "queue_name=${aws_sqs_queue.chat_service_queue.name}" >> /etc/chat.ini
      echo "bucket_name=${data.terraform_remote_state.oob.outputs.bucket_name}" >> /etc/chat.ini
      echo "table_name=${aws_dynamodb_table.locking_table.name}" >> /etc/chat.ini
      echo "region=${data.aws_region.current.name}" >> /etc/chat.ini
      systemctl enable chat.service
      systemctl start chat.service
      EOF
  )

  tags = {
    Name = "Chat Service Instance"
  }
}

resource "aws_autoscaling_group" "chat_service" {
  name                = "chat-service-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = 1
  max_size            = 10
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.chat_service.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Chat Service Instance"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_depth_alarm" {
  alarm_name          = "sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors SQS queue depth"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  ok_actions          = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    QueueName = aws_sqs_queue.chat_service_queue.name
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.chat_service.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.chat_service.name
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "asg_name" {
  value = aws_autoscaling_group.chat_service.name
}
