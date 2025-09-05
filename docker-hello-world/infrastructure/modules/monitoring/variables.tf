# Variables for Monitoring Module

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

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "frontend_service_name" {
  description = "Name of the frontend ECS service"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the backend ECS service"
  type        = string
}

variable "database_identifier" {
  description = "RDS database instance identifier"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

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