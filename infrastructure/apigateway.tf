resource "aws_api_gateway_rest_api" "chat" {
  name        = "pubkey.chat"
  description = "API for Chat Service"
}

resource "aws_api_gateway_resource" "assets" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_rest_api.chat.root_resource_id
  path_part   = "assets"
}

resource "aws_api_gateway_resource" "asset_name" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_resource.assets.id
  path_part   = "{name}"
}

resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_rest_api.chat.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_resource" "topics" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_rest_api.chat.root_resource_id
  path_part   = "topics"
}

resource "aws_api_gateway_resource" "messages_name" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_resource.messages.id
  path_part   = "{name}"
}

resource "aws_api_gateway_resource" "topics_name" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  parent_id   = aws_api_gateway_resource.topics.id
  path_part   = "{name}"
}

resource "aws_api_gateway_method" "create_message" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_message" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_resource.messages_name.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.name" = true
  }
}

resource "aws_api_gateway_method" "get_topic" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_resource.topics_name.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.name" = true
  }
}

resource "aws_api_gateway_method" "get_asset" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_resource.asset_name.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.name" = true
  }
}

resource "aws_api_gateway_method" "get_root" {
  rest_api_id   = aws_api_gateway_rest_api.chat.id
  resource_id   = aws_api_gateway_rest_api.chat.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_message" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.create_message.http_method
  type        = "AWS"

  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${aws_sqs_queue.chat_service_queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageBody=$util.urlEncode($input.body)
EOF
  }
}

resource "aws_api_gateway_integration" "get_message" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages_name.id
  http_method = aws_api_gateway_method.get_message.http_method
  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.chat_service_bucket.id}/messages/{name}"
  request_parameters = {
    "integration.request.path.name" = "method.request.path.name"
  }
}

resource "aws_api_gateway_integration" "get_topic" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.topics_name.id
  http_method = aws_api_gateway_method.get_message.http_method
  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.chat_service_bucket.id}/topics/{name}"
  request_parameters = {
    "integration.request.path.name" = "method.request.path.name"
  }
}

resource "aws_api_gateway_integration" "get_asset" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.asset_name.id
  http_method = aws_api_gateway_method.get_message.http_method
  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.chat_service_bucket.id}/assets/{name}"
  request_parameters = {
    "integration.request.path.name" = "method.request.path.name"
  }
}

resource "aws_api_gateway_integration" "get_root" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_rest_api.chat.root_resource_id
  http_method = aws_api_gateway_method.get_message.http_method
  credentials = aws_iam_role.api_gateway_sqs_role.arn

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.chat_service_bucket.id}/index.html"
}

resource "aws_api_gateway_method_response" "get_message_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages_name.id
  http_method = aws_api_gateway_method.get_message.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "get_topic_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.topics_name.id
  http_method = aws_api_gateway_method.get_topic.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "get_asset_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.asset_name.id
  http_method = aws_api_gateway_method.get_asset.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "get_root_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_rest_api.chat.root_resource_id
  http_method = aws_api_gateway_method.get_asset.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "get_message_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.messages_name.id
  http_method = aws_api_gateway_method.get_message.http_method
  status_code = aws_api_gateway_method_response.get_message_200.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  depends_on = [
    aws_api_gateway_integration.get_message
  ]
}

resource "aws_api_gateway_integration_response" "get_topic_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.topics_name.id
  http_method = aws_api_gateway_method.get_topic.http_method
  status_code = aws_api_gateway_method_response.get_topic_200.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  depends_on = [
    aws_api_gateway_integration.get_topic
  ]
}

resource "aws_api_gateway_integration_response" "get_asset_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_resource.asset_name.id
  http_method = aws_api_gateway_method.get_asset.http_method
  status_code = aws_api_gateway_method_response.get_asset_200.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  depends_on = [
    aws_api_gateway_integration.get_asset
  ]
}

resource "aws_api_gateway_integration_response" "get_root_200" {
  rest_api_id = aws_api_gateway_rest_api.chat.id
  resource_id = aws_api_gateway_rest_api.chat.root_resource_id
  http_method = aws_api_gateway_method.get_root.http_method
  status_code = aws_api_gateway_method_response.get_root_200.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  depends_on = [
    aws_api_gateway_integration.get_root
  ]
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
    aws_api_gateway_integration.create_message,
  ]

  triggers = {
    # This will trigger a new deployment on changes to any of these resources
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.assets.id,
      aws_api_gateway_resource.asset_name.id,
      aws_api_gateway_resource.messages.id,
      aws_api_gateway_resource.topics.id,
      aws_api_gateway_resource.messages_name.id,
      aws_api_gateway_resource.topics_name.id,
      aws_api_gateway_method.create_message.id,
      aws_api_gateway_method.get_message.id,
      aws_api_gateway_method.get_topic.id,
      aws_api_gateway_method.get_asset.id,
      aws_api_gateway_method.get_root.id,
      aws_api_gateway_integration.create_message.id,
      aws_api_gateway_integration.get_message.id,
      aws_api_gateway_integration.get_topic.id,
      aws_api_gateway_integration.get_asset.id,
      aws_api_gateway_integration.get_root.id,
      aws_api_gateway_method_response.get_message_200.id,
      aws_api_gateway_method_response.get_topic_200.id,
      aws_api_gateway_method_response.get_asset_200.id,
      aws_api_gateway_method_response.get_root_200.id,
      aws_api_gateway_integration_response.get_message_200.id,
      aws_api_gateway_integration_response.get_topic_200.id,
      aws_api_gateway_integration_response.get_asset_200.id,
      aws_api_gateway_integration_response.get_root_200.id,
      aws_api_gateway_method_response.create_message_200.id,
      aws_api_gateway_integration_response.create_message_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

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
    format          = "$context.requestTime $context.httpMethod $context.path ($context.resourcePath) $context.status [Err: $context.error.messageString] [IntErr: $context.integrationErrorMessage] $context.requestId"
  }

  variables = {
    "CloudFrontDomainName" = aws_cloudfront_distribution.api_distribution.domain_name
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
        Effect   = "Allow",
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.chat_service_queue.arn
      },
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.chat_service_bucket.arn}/*"
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

output "write_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/messages"
}

output "read_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/messages/{name}"
}

output "read_topic_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/topics/{name}"
}
