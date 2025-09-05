# Outputs for Security Hardening Module

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.enable_https ? aws_acm_certificate.app_cert[0].arn : null
}

output "security_headers_lambda_arn" {
  description = "ARN of the security headers Lambda function"
  value       = var.enable_security_headers ? aws_lambda_function.security_headers[0].arn : null
}

output "waf_log_group_name" {
  description = "Name of the WAF CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf_logs.name
}

output "waf_rules_summary" {
  description = "Summary of WAF rules configured"
  value = {
    common_rule_set          = "Enabled"
    known_bad_inputs        = "Enabled"
    sqli_protection        = "Enabled"
    rate_limiting          = "Enabled (${var.rate_limit_per_5min} requests/5min)"
    geo_blocking           = length(var.blocked_countries) > 0 ? "Enabled (${join(", ", var.blocked_countries)})" : "Disabled"
    ip_allowlist          = length(var.allowed_ips) > 0 ? "Enabled (${length(var.allowed_ips)} IPs)" : "Disabled"
  }
}

output "security_features_summary" {
  description = "Summary of security features enabled"
  value = {
    waf_protection       = "Enabled"
    https_encryption     = var.enable_https ? "Enabled" : "Disabled"
    security_headers     = var.enable_security_headers ? "Enabled" : "Disabled"
    rate_limiting       = "Enabled"
    sql_injection_protection = "Enabled"
    xss_protection      = "Enabled"
    geo_blocking        = length(var.blocked_countries) > 0 ? "Enabled" : "Disabled"
  }
}