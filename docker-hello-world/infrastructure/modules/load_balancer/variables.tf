# Load Balancer Module Variables
# Configuration options for Application Load Balancer and related resources

variable "name_prefix" {
  description = "Prefix for resource names to ensure consistent naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the load balancer target group will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the load balancer will be deployed"
  type        = list(string)
  
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Load balancer requires at least 2 public subnets in different AZs for high availability."
  }
  
  # TEACHING POINT: ALB Subnet Requirements
  # - Must be in public subnets (with internet gateway route)
  # - Must span at least 2 availability zones
  # - Each subnet must have available IP addresses
  # - Subnets must have /27 or larger CIDR blocks
}

variable "alb_sg_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
  
  # This security group should allow:
  # - Inbound: HTTP (80) and HTTPS (443) from 0.0.0.0/0
  # - Outbound: HTTP to target group port (e.g., 3000) to ECS security group
}

variable "domain_name" {
  description = "Primary domain name for SSL certificate (leave empty to use ALB DNS name)"
  type        = string
  default     = ""
  
  validation {
    condition = var.domain_name == "" || can(regex("^[a-z0-9]([a-z0-9\\-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9\\-]{0,61}[a-z0-9])?)*$", var.domain_name))
    error_message = "Domain name must be a valid DNS name (lowercase, alphanumeric, hyphens allowed)."
  }
  
  # COST CONSIDERATION:
  # - Empty string: Uses ALB DNS name (free)
  # - Custom domain: Requires Route53 hosted zone (~$0.50/month per domain)
}

variable "enable_access_logs" {
  description = "Enable ALB access logs to S3 (additional storage costs)"
  type        = bool
  default     = false
  
  # ACCESS LOGS BENEFITS:
  # - Detailed request/response information
  # - Security analysis and debugging
  # - Performance analysis
  # - Compliance requirements
  # 
  # COST: S3 storage charges apply (~$0.023/GB/month)
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required if enable_access_logs = true)"
  type        = string
  default     = ""
  
  validation {
    condition = var.enable_access_logs == false || (var.enable_access_logs == true && var.access_logs_bucket != "")
    error_message = "access_logs_bucket must be specified when enable_access_logs is true."
  }
}

variable "ssl_policy" {
  description = "SSL security policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  
  validation {
    condition = contains([
      "ELBSecurityPolicy-TLS-1-0-2015-04",
      "ELBSecurityPolicy-TLS-1-1-2017-01", 
      "ELBSecurityPolicy-TLS-1-2-2017-01",
      "ELBSecurityPolicy-TLS-1-2-Ext-2018-06",
      "ELBSecurityPolicy-FS-2018-06",
      "ELBSecurityPolicy-FS-1-1-2019-08",
      "ELBSecurityPolicy-FS-1-2-2019-08",
      "ELBSecurityPolicy-FS-1-2-Res-2019-08"
    ], var.ssl_policy)
    error_message = "SSL policy must be a valid ELB security policy."
  }
  
  # SSL POLICY GUIDE:
  # - TLS-1-2-2017-01: Good balance of security and compatibility (recommended)
  # - FS-*: Forward Secrecy policies (higher security, may break older clients)
  # - TLS-1-0/1-1: Older protocols (only for legacy compatibility)
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/"
  
  validation {
    condition     = can(regex("^/", var.health_check_path))
    error_message = "Health check path must start with '/'."
  }
  
  # HEALTH CHECK BEST PRACTICES:
  # - Use a lightweight endpoint (e.g., /health, /ping)
  # - Verify application dependencies (database, external services)
  # - Return appropriate HTTP status codes
  # - Keep response time under 5 seconds
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks before marking target healthy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before marking target unhealthy"
  type        = number
  default     = 3
  
  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "health_check_interval" {
  description = "Approximate amount of time between health checks (seconds)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Amount of time to wait when receiving a response from health check (seconds)"
  type        = number
  default     = 5
  
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "deregistration_delay" {
  description = "Time to wait for existing requests to complete when deregistering targets (seconds)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.deregistration_delay >= 0 && var.deregistration_delay <= 3600
    error_message = "Deregistration delay must be between 0 and 3600 seconds."
  }
  
  # DEPLOYMENT CONSIDERATIONS:
  # - Shorter delays: Faster deployments, risk of connection errors
  # - Longer delays: Graceful connection handling, slower deployments
  # - 30 seconds is good for most web applications
  # - Increase for long-running requests or file uploads
}

variable "idle_timeout" {
  description = "Time in seconds that connections are allowed to be idle"
  type        = number
  default     = 60
  
  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
  
  # IDLE TIMEOUT CONSIDERATIONS:
  # - Web applications: 60-300 seconds
  # - APIs: 30-60 seconds  
  # - WebSocket/streaming: Higher values (3600+)
  # - File uploads: Consider timeout vs upload time
}

variable "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL to associate with the load balancer (optional)"
  type        = string
  default     = ""
  
  # WAF INTEGRATION:
  # - Provides additional security layer at the load balancer level
  # - Filters malicious requests before they reach application
  # - Includes rate limiting, SQL injection protection, XSS protection
  # - Additional cost: ~$5/month + request charges
}

variable "tags" {
  description = "Map of tags to assign to all load balancer resources"
  type        = map(string)
  default     = {}
  
  # RECOMMENDED TAGS:
  # - Environment: dev/staging/prod
  # - Project: application/service name
  # - Owner: team or individual responsible
  # - CostCenter: for billing allocation
  # - Backup: backup retention requirements
}