# Variables for Security Hardening Module

variable "environment" {
  description = "Environment name (demo, dev, prod)"
  type        = string

  validation {
    condition     = contains(["demo", "dev", "prod"], var.environment)
    error_message = "Environment must be demo, dev, or prod."
  }
}

variable "aws_region" {
  description = "The AWS region for resources"
  type        = string
}

variable "load_balancer_arn" {
  description = "ARN of the Application Load Balancer to protect"
  type        = string
}

variable "enable_https" {
  description = "Enable HTTPS with ACM certificate"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for SSL certificate (leave empty for demo)"
  type        = string
  default     = ""
}

variable "enable_security_headers" {
  description = "Enable security headers via Lambda@Edge"
  type        = bool
  default     = true
}

variable "rate_limit_per_5min" {
  description = "Rate limit per IP per 5 minutes"
  type        = number
  default     = 1000

  validation {
    condition     = var.rate_limit_per_5min >= 100 && var.rate_limit_per_5min <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000."
  }
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for country in var.blocked_countries : length(country) == 2
    ])
    error_message = "Country codes must be 2-character ISO 3166-1 alpha-2 codes."
  }
}

variable "allowed_ips" {
  description = "List of IP addresses/CIDR blocks to always allow"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for security alerts"
  type        = string
  default     = ""
}

variable "waf_blocked_requests_threshold" {
  description = "Threshold for WAF blocked requests alarm"
  type        = number
  default     = 100

  validation {
    condition     = var.waf_blocked_requests_threshold >= 10 && var.waf_blocked_requests_threshold <= 10000
    error_message = "WAF blocked requests threshold must be between 10 and 10,000."
  }
}