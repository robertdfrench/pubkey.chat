# Create CloudFront distribution
resource "aws_cloudfront_distribution" "api_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for API Gateway"
  default_root_object = ""

  origin {
    # https://oe9xunloch.execute-api.us-east-1.amazonaws.com/
    domain_name = replace(
      replace(
        aws_api_gateway_deployment.chat.invoke_url,
        "https://",
        ""),
      "/",
      "")
    origin_id   = "APIGateway"
    origin_path = "/prod"  # Add this line to specify the stage

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "APIGateway"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/topics/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "APIGateway"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

# Instead of adding CloudFront domain to API Gateway stage, 
# create a custom domain for API Gateway (optional)
# resource "aws_api_gateway_domain_name" "chat_api" {
#   domain_name              = "pubkey.chat"  # Replace with your domain
#   regional_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"  # Replace with your SSL cert ARN
# 
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }
# 
# resource "aws_api_gateway_base_path_mapping" "chat_api" {
#   api_id      = aws_api_gateway_rest_api.chat.id
#   stage_name  = aws_api_gateway_stage.prod.stage_name
#   domain_name = aws_api_gateway_domain_name.chat_api.domain_name
# }

# Output both CloudFront URL and API Gateway custom domain
output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.api_distribution.domain_name}"
}
