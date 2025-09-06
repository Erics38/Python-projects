# ECS Module Variables
# Configuration for container orchestration and application deployment

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where ECS tasks will run"
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "ECS requires at least 1 private subnet."
  }
  
  # TEACHING POINT: Why Private Subnets?
  # - Security: Containers don't get public IP addresses
  # - Cost: No data transfer charges for traffic between containers
  # - Compliance: Many regulations require private networking
  # - Architecture: Clean separation between public (ALB) and private (apps)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  
  # This security group should allow:
  # - Inbound: Traffic from ALB on application port
  # - Outbound: HTTPS to AWS APIs, database port to RDS
}

variable "target_group_arn" {
  description = "ALB target group ARN for container registration"
  type        = string
  
  # ECS automatically registers/deregisters container IPs with this target group
}

variable "http_listener_arn" {
  description = "ARN of the HTTP listener for dependency management"
  type        = string
  default     = ""
  
  # Used to ensure load balancer is fully configured before ECS service starts
}

# DATABASE CONNECTION DETAILS
variable "db_host" {
  description = "Database host endpoint for application connection"
  type        = string
  sensitive   = true
  
  # This comes from the RDS module output
}

variable "db_secret_arn" {
  description = "ARN of AWS Secrets Manager secret containing database credentials"
  type        = string
  sensitive   = true
  
  # Used to inject database password as environment variable
  # More secure than hardcoding passwords in container images
}

# CONTAINER IMAGES
variable "frontend_image" {
  description = "Container image URI for frontend application"
  type        = string
  default     = "nginx:alpine"
  
  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*(:.*)?$", var.frontend_image))
    error_message = "Frontend image must be a valid container image name."
  }
  
  # TEACHING POINT: Container Image Sources
  # - Docker Hub: nginx:alpine (public images)
  # - ECR Private: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
  # - ECR Public: public.ecr.aws/nginx/nginx:alpine
}

variable "backend_image" {
  description = "Container image URI for backend application"
  type        = string
  default     = "node:18-alpine"
  
  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*(:.*)?$", var.backend_image))
    error_message = "Backend image must be a valid container image name."
  }
}

# COMPUTE RESOURCES
variable "container_cpu" {
  description = "CPU units for ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 256
  
  validation {
    condition = contains([256, 512, 1024, 2048, 4096], var.container_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
  
  # FARGATE CPU/MEMORY COMBINATIONS (must be valid pairs):
  # CPU   | Memory Options (MB)
  # ------|--------------------
  # 256   | 512, 1024, 2048
  # 512   | 1024 to 4096 (1GB increments)
  # 1024  | 2048 to 8192 (1GB increments)
  # 2048  | 4096 to 16384 (1GB increments)
  # 4096  | 8192 to 30720 (1GB increments)
}

variable "container_memory" {
  description = "Memory for ECS tasks in MB"
  type        = number
  default     = 512
  
  validation {
    condition     = var.container_memory >= 128 && var.container_memory <= 30720
    error_message = "Memory must be between 128 and 30720 MB."
  }
  
  # COST CONSIDERATION:
  # Fargate pricing is based on vCPU-seconds and GB-seconds
  # Optimize by right-sizing containers based on actual usage
}

variable "container_port" {
  description = "Port number that backend application listens on"
  type        = number
  default     = 3000
  
  validation {
    condition     = var.container_port >= 1024 && var.container_port <= 65535
    error_message = "Container port must be between 1024 and 65535."
  }
  
  # BEST PRACTICE: Use non-privileged ports (>= 1024)
}

# SERVICE CONFIGURATION
variable "desired_count" {
  description = "Number of ECS tasks to run for each service"
  type        = number
  default     = 1
  
  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 100
    error_message = "Desired count must be between 0 and 100."
  }
  
  # DEPLOYMENT CONSIDERATIONS:
  # - 0: Service stopped (for cost savings)
  # - 1: Single instance (no high availability)
  # - 2+: High availability, rolling deployments
}

variable "health_check_grace_period" {
  description = "Health check grace period for ECS service in seconds"
  type        = number
  default     = 60
  
  validation {
    condition     = var.health_check_grace_period >= 0 && var.health_check_grace_period <= 2147483647
    error_message = "Health check grace period must be a valid positive integer."
  }
  
  # Grace period prevents premature health check failures during:
  # - Application startup time
  # - Database connection establishment  
  # - Cache warming
  # - SSL certificate loading
}

# AUTO SCALING CONFIGURATION
variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
  
  # Auto-scaling adds complexity but provides:
  # - Automatic capacity management
  # - Cost optimization (scale down during low traffic)
  # - Performance optimization (scale up during high traffic)
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks when autoscaling is enabled"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_capacity >= 0
    error_message = "Minimum capacity must be 0 or greater."
  }
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks when autoscaling is enabled"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_capacity >= 1
    error_message = "Maximum capacity must be 1 or greater."
  }
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
  
  validation {
    condition     = var.cpu_target_value >= 10 && var.cpu_target_value <= 90
    error_message = "CPU target value must be between 10 and 90 percent."
  }
  
  # SCALING CONSIDERATIONS:
  # - Too low (< 50%): Expensive, frequent scaling
  # - Too high (> 80%): Poor performance, slow scaling
  # - 70% is often a good balance
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 80
  
  validation {
    condition     = var.memory_target_value >= 10 && var.memory_target_value <= 90
    error_message = "Memory target value must be between 10 and 90 percent."
  }
  
  # Memory scaling is often less useful than CPU scaling
  # Most web applications are CPU-bound, not memory-bound
}

# DEPLOYMENT CONFIGURATION
variable "deployment_maximum_percent" {
  description = "Maximum percent of desired count during deployment"
  type        = number
  default     = 200
  
  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 200
    error_message = "Maximum percent must be between 100 and 200."
  }
  
  # DEPLOYMENT STRATEGIES:
  # - 100%: Replace containers one-by-one (slower, zero extra cost)
  # - 200%: Run old and new containers simultaneously (faster, temporary 2x cost)
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percent of desired count during deployment"
  type        = number
  default     = 100
  
  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "Minimum healthy percent must be between 0 and 100."
  }
  
  # AVAILABILITY vs SPEED:
  # - 100%: No downtime during deployments (requires max_percent > 100)
  # - 50%: Allow half containers to be down during deployment
  # - 0%: Allow all containers to be replaced simultaneously (fastest but downtime)
}

# ENVIRONMENT CONFIGURATION
variable "environment" {
  description = "Environment name (dev, staging, prod, demo)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, demo."
  }
  
  # This gets passed to containers as NODE_ENV or similar
}

variable "tags" {
  description = "Map of tags to assign to all ECS resources"
  type        = map(string)
  default     = {}
  
  # RECOMMENDED ECS-SPECIFIC TAGS:
  # - Service: frontend/backend/api
  # - Cluster: production/staging/dev
  # - Version: git commit SHA or semantic version
  # - DeployedBy: CI/CD system or user
}