resource "aws_api_gateway_rest_api" "chat" {
  name        = "pubkey.chat"
  description = "API for Chat Service"
}

resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_rest_api.chat.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_method" "create_message" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_message" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.create_message.http_method
  type        = "AWS"

  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${aws_sqs_queue.chat_service_queue.name}"

  request_templates = {
    "application/json" = <<EOF
{
  "Action": "SendMessage",
  "QueueUrl": "${aws_sqs_queue.chat_service_queue.url}",
  "MessageBody": "$input.body"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "create_message_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.create_message.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "create_message_200" {
  depends_on = [
    aws_api_gateway_integration.create_message
  ]

  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.create_message.http_method
  status_code = aws_api_gateway_method_response.create_message_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_deployment" "chat" {
  depends_on = [
    aws_api_gateway_integration.create_message
  ]

  rest_api_id = aws_api_gateway_rest_api.chat.id
}

resource "aws_cloudwatch_log_group" "chat" {
  name = "/aws/apigateway/pubkey-chat"
}

resource "aws_api_gateway_stage" "prod" {
  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_iam_role_policy_attachment.api_gateway_cloudwatch_attachment
  ]

  deployment_id = aws_api_gateway_deployment.chat.id
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.chat.arn
    format          = "$context.requestId $context.identity.sourceIp $context.identity.caller $context.identity.user $context.requestTime $context.httpMethod $context.resourcePath $context.status $context.protocol $context.responseLength"
  }
}

resource "aws_iam_role" "api_gateway_sqs_role" {
  name = "APIGatewaySQSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_sqs_policy" {
  name        = "APIGatewaySQSPolicy"
  description = "Policy for allowing API Gateway to send messages to SQS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.chat_service_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_sqs_policy_attachment" {
  role       = aws_iam_role.api_gateway_sqs_role.name
  policy_arn = aws_iam_policy.api_gateway_sqs_policy.arn
}


resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_cloudwatch_policy" {
  name        = "APIGatewayCloudWatchLogsPolicy"
  description = "IAM policy for allowing API Gateway to write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = aws_iam_policy.api_gateway_cloudwatch_policy.arn
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}
