# Database Module Variables
# These variables allow customization of the RDS PostgreSQL instance
# while maintaining sensible defaults for different environments

variable "name_prefix" {
  description = "Prefix for resource names - creates consistent naming across all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the database subnet group will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for database placement - must span 2+ AZs"
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Database requires at least 2 private subnets across different AZs for high availability."
  }
}

variable "database_sg_id" {
  description = "Security group ID for database access control"
  type        = string
}

variable "db_password" {
  description = "Master password for the database - should be randomly generated"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Database password must be at least 16 characters for security."
  }
}

variable "instance_class" {
  description = "RDS instance class - determines CPU, memory, and network performance"
  type        = string
  default     = "db.t3.micro"
  
  # COST OPTIMIZATION: t3.micro is free tier eligible
  # PRODUCTION: Consider db.t3.small or larger for real workloads
}

variable "allocated_storage" {
  description = "Initial database storage in GB - can auto-scale up to max_allocated_storage"
  type        = number
  default     = 20
  
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 1000
    error_message = "Storage must be between 20GB (minimum) and 1000GB (reasonable max for demo)."
  }
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 = disabled, max 35)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention must be 0-35 days (AWS limit)."
  }
  
  # TEACHING POINT: Backup Retention Strategy
  # - 0 days: No backups (only for development/testing)
  # - 1-7 days: Basic protection for demos and development
  # - 14-30 days: Production workloads
  # - 35 days: Maximum for compliance requirements
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability (increases cost ~2x)"
  type        = bool
  default     = false
  
  # COST vs AVAILABILITY TRADE-OFF:
  # - false: Single AZ, lower cost, some downtime during maintenance
  # - true: Multi-AZ, higher cost, automatic failover, near-zero downtime
}

variable "publicly_accessible" {
  description = "Whether the database should be accessible from the internet"
  type        = bool
  default     = false
  
  # SECURITY BEST PRACTICE: Should always be false for production
  # Only set to true for development/debugging (with proper security groups)
}

variable "enable_deletion_protection" {
  description = "Prevent accidental database deletion"
  type        = bool
  default     = false
  
  # DEMO vs PRODUCTION:
  # - false: Easy to delete for demo cleanup
  # - true: Prevents accidental deletion in production
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for detailed database monitoring"
  type        = bool
  default     = false
  
  # COST CONSIDERATION: Performance Insights is free for 7 days retention
  # Longer retention periods incur additional costs
}

variable "environment" {
  description = "Environment name (used for resource naming and configuration)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, demo."
  }
}

variable "tags" {
  description = "Map of tags to assign to all database resources"
  type        = map(string)
  default     = {}
  
  # BEST PRACTICE: Consistent tagging helps with:
  # - Cost allocation and tracking
  # - Resource management and automation
  # - Compliance and governance
  # - Backup and disaster recovery planning
}