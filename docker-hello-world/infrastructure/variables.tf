# Variables for Guestbook Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod, demo)"
  type        = string
  default     = "demo"
  
  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, demo."
  }
}

variable "frontend_image" {
  description = "Frontend container image URI"
  type        = string
  default     = "nginx:alpine"
}

variable "backend_image" {
  description = "Backend container image URI"  
  type        = string
  default     = "node:18-alpine"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_class))
    error_message = "Instance class must be a valid RDS instance type."
  }
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }
}

variable "backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for RDS instance"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make RDS instance publicly accessible"
  type        = bool
  default     = false
}

variable "container_cpu" {
  description = "CPU units for ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 256
  
  validation {
    condition = contains([256, 512, 1024, 2048, 4096], var.container_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "container_memory" {
  description = "Memory for ECS tasks in MB"
  type        = number
  default     = 512
  
  validation {
    condition     = var.container_memory >= 128 && var.container_memory <= 30720
    error_message = "Memory must be between 128 and 30720 MB."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
  
  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 10
    error_message = "Desired count must be between 0 and 10."
  }
}

variable "health_check_grace_period" {
  description = "Health check grace period for ECS service in seconds"
  type        = number
  default     = 60
}

variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks when autoscaling is enabled"
  type        = number
  default     = 3
}

# Monitoring and Alerting Variables
variable "alert_email" {
  description = "Email address for CloudWatch alerts (optional)"
  type        = string
  default     = ""

  validation {
    condition = var.alert_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Alert email must be a valid email address or empty string."
  }
}

variable "enable_container_insights" {
  description = "Enable Container Insights for ECS cluster"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold >= 50 && var.cpu_alarm_threshold <= 95
    error_message = "CPU alarm threshold must be between 50 and 95."
  }
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarms (percentage)"
  type        = number
  default     = 85

  validation {
    condition     = var.memory_alarm_threshold >= 60 && var.memory_alarm_threshold <= 95
    error_message = "Memory alarm threshold must be between 60 and 95."
  }
}

variable "response_time_threshold" {
  description = "Response time threshold for ALB alarms (seconds)"
  type        = number
  default     = 2

  validation {
    condition     = var.response_time_threshold >= 0.5 && var.response_time_threshold <= 10
    error_message = "Response time threshold must be between 0.5 and 10 seconds."
  }
}

# Security Hardening Variables
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
  description = "Rate limit per IP per 5 minutes for WAF"
  type        = number
  default     = 1000

  validation {
    condition     = var.rate_limit_per_5min >= 100 && var.rate_limit_per_5min <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000."
  }
}

variable "blocked_countries" {
  description = "List of country codes to block via WAF (ISO 3166-1 alpha-2)"
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
  description = "List of IP addresses/CIDR blocks to always allow through WAF"
  type        = list(string)
  default     = []
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