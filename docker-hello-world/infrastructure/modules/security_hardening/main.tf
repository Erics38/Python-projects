# Security Hardening Module
# Web Application Firewall, SSL certificates, and security headers

# ACM SSL Certificate for HTTPS
resource "aws_acm_certificate" "app_cert" {
  count             = var.enable_https ? 1 : 0
  domain_name       = var.domain_name != "" ? var.domain_name : "${var.environment}.example.com"
  validation_method = "DNS"

  subject_alternative_names = var.domain_name != "" ? [
    "*.${var.domain_name}"
  ] : []

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-ssl-certificate"
    Environment = var.environment
  }
}

# WAF Web ACL for Application Load Balancer
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.environment}-guestbook-waf"
  scope = "REGIONAL" # For ALB (CLOUDFRONT for CloudFront)

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: SQL Injection Rule Set
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5min
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Geo-blocking Rule (Optional)
  dynamic "rule" {
    for_each = var.blocked_countries != [] ? [1] : []
    content {
      name     = "GeoBlockingRule"
      priority = 5

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoBlockingRuleMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rule 6: IP Allowlist Rule (Optional)
  dynamic "rule" {
    for_each = var.allowed_ips != [] ? [1] : []
    content {
      name     = "IPAllowlistRule"
      priority = 6

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowed_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IPAllowlistRuleMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = {
    Name        = "${var.environment}-waf"
    Environment = var.environment
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wafMetric"
    sampled_requests_enabled   = true
  }
}

# IP Set for Allowed IPs (Optional)
resource "aws_wafv2_ip_set" "allowed_ips" {
  count              = var.allowed_ips != [] ? 1 : 0
  name               = "${var.environment}-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.allowed_ips

  tags = {
    Name        = "${var.environment}-allowed-ips"
    Environment = var.environment
  }
}

# WAF Log Group
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/${var.environment}-guestbook"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-waf-logs"
    Environment = var.environment
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  redacted_fields {
    single_header {
      name = "x-api-key"
    }
  }
}

# Security Headers Lambda Function (for CloudFront)
resource "aws_lambda_function" "security_headers" {
  count         = var.enable_security_headers ? 1 : 0
  filename      = "security_headers.zip"
  function_name = "${var.environment}-security-headers"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 5

  source_code_hash = data.archive_file.security_headers_zip[0].output_base64sha256

  tags = {
    Name        = "${var.environment}-security-headers"
    Environment = var.environment
  }
}

# Lambda function code for security headers
data "archive_file" "security_headers_zip" {
  count       = var.enable_security_headers ? 1 : 0
  type        = "zip"
  output_path = "security_headers.zip"
  source {
    content = <<EOF
exports.handler = async (event) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;
    
    // Security Headers
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubdomains; preload'
    }];
    
    headers['content-security-policy'] = [{
        key: 'Content-Security-Policy',
        value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'"
    }];
    
    headers['x-frame-options'] = [{
        key: 'X-Frame-Options',
        value: 'DENY'
    }];
    
    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options',
        value: 'nosniff'
    }];
    
    headers['referrer-policy'] = [{
        key: 'Referrer-Policy',
        value: 'strict-origin-when-cross-origin'
    }];
    
    headers['permissions-policy'] = [{
        key: 'Permissions-Policy',
        value: 'geolocation=(), microphone=(), camera=()'
    }];
    
    headers['x-xss-protection'] = [{
        key: 'X-XSS-Protection',
        value: '1; mode=block'
    }];
    
    return response;
};
EOF
    filename = "index.js"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  count = var.enable_security_headers ? 1 : 0
  name  = "${var.environment}-security-headers-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-lambda-role"
    Environment = var.environment
  }
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.enable_security_headers ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role[0].name
}

# WAF Alarms
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.environment}-waf-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.waf_blocked_requests_threshold
  alarm_description   = "This metric monitors WAF blocked requests"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = var.aws_region
  }

  tags = {
    Name        = "${var.environment}-waf-blocked-requests-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_rate_limit_triggered" {
  alarm_name          = "${var.environment}-waf-rate-limit-triggered"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RateLimitRuleMetric"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors WAF rate limiting triggers"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = var.aws_region
  }

  tags = {
    Name        = "${var.environment}-waf-rate-limit-alarm"
    Environment = var.environment
  }
}

# WAF Web ACL Association with Load Balancer
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.load_balancer_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}