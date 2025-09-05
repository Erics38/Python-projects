# ECS Module Outputs
# Provides information about the container infrastructure for monitoring and integration

# CLUSTER INFORMATION
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
  
  # Used for AWS CLI operations:
  # aws ecs list-services --cluster <cluster_name>
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
  
  # Unique identifier for the cluster across all AWS services
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
  
  # Short identifier used internally by Terraform
}

# SERVICE INFORMATION
output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = aws_ecs_service.frontend.name
  
  # Used for deployment and scaling operations
}

output "frontend_service_arn" {
  description = "ARN of the frontend ECS service"
  value       = aws_ecs_service.frontend.id  # Note: .id returns ARN for ECS services
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "backend_service_arn" {
  description = "ARN of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

# TASK DEFINITION INFORMATION
output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
  
  # Full ARN includes revision number:
  # arn:aws:ecs:region:account:task-definition/family:revision
}

output "frontend_task_definition_family" {
  description = "Family name of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.family
  
  # Family name without revision number (useful for deployments)
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "backend_task_definition_family" {
  description = "Family name of the backend task definition"
  value       = aws_ecs_task_definition.backend.family
}

# IAM ROLE INFORMATION
output "execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
  
  # This role is used by ECS to set up containers (pull images, logs, etc.)
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
  
  # This role is used by application code to access AWS services
}

output "execution_role_name" {
  description = "Name of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.name
  
  # Used for attaching additional policies if needed
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

# CAPACITY PROVIDER INFORMATION
output "capacity_providers" {
  description = "List of capacity providers available to the cluster"
  value       = aws_ecs_cluster.main.capacity_providers
  
  # Shows whether Fargate, Fargate Spot, or EC2 are available
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.default_capacity_provider_strategy
  
  # Shows how tasks are distributed across capacity providers by default
}

# SERVICE DISCOVERY (if implemented)
# output "service_discovery_namespace" {
#   description = "Service discovery namespace for inter-service communication"
#   value       = aws_service_discovery_private_dns_namespace.main.name
# }

# NETWORKING INFORMATION
output "service_subnets" {
  description = "Subnets where ECS tasks are running"
  value       = var.private_subnet_ids
  
  # Helps understand the network topology
}

output "service_security_group" {
  description = "Security group ID used by ECS tasks"
  value       = var.ecs_sg_id
  
  # Reference to security group controlling container traffic
}

# SCALING CONFIGURATION (if auto-scaling is enabled)
output "autoscaling_enabled" {
  description = "Whether auto-scaling is enabled for services"
  value       = var.enable_autoscaling
}

output "scaling_configuration" {
  description = "Auto-scaling configuration details"
  value = var.enable_autoscaling ? {
    min_capacity        = var.min_capacity
    max_capacity        = var.max_capacity
    cpu_target_value    = var.cpu_target_value
    memory_target_value = var.memory_target_value
  } : null
}

# DEPLOYMENT CONFIGURATION
output "deployment_configuration" {
  description = "Deployment strategy configuration"
  value = {
    maximum_percent         = var.deployment_maximum_percent
    minimum_healthy_percent = var.deployment_minimum_healthy_percent
    circuit_breaker_enabled = true
    rollback_enabled       = true
  }
}

# RESOURCE CONFIGURATION SUMMARY
output "resource_configuration" {
  description = "Container resource allocation summary"
  value = {
    cpu_units    = var.container_cpu
    memory_mb    = var.container_memory
    vcpu_equivalent = var.container_cpu / 1024
    cost_estimate = {
      cpu_cost_per_hour    = (var.container_cpu / 1024) * 0.04048
      memory_cost_per_hour = (var.container_memory / 1024) * 0.004445
      total_per_hour       = ((var.container_cpu / 1024) * 0.04048) + ((var.container_memory / 1024) * 0.004445)
      total_per_month      = (((var.container_cpu / 1024) * 0.04048) + ((var.container_memory / 1024) * 0.004445)) * 24 * 30 * var.desired_count * 2  # 2 services
    }
  }
}

# OPERATIONAL INFORMATION
output "log_group_name" {
  description = "CloudWatch log group name for ECS containers"
  value       = "/aws/ecs/${var.name_prefix}"
  
  # Used for viewing container logs:
  # aws logs tail /aws/ecs/myapp-demo --follow
}

output "container_insights_enabled" {
  description = "Whether Container Insights monitoring is enabled"
  value       = true  # We enabled this in the cluster configuration
  
  # Container Insights provides detailed container and task metrics
}

# SERVICE STATUS INFORMATION
output "services_summary" {
  description = "Summary of all ECS services"
  value = {
    frontend = {
      name            = aws_ecs_service.frontend.name
      desired_count   = var.desired_count
      platform_version = aws_ecs_service.frontend.platform_version
      launch_type     = "FARGATE"
      load_balancer_integrated = true
    }
    backend = {
      name            = aws_ecs_service.backend.name
      desired_count   = var.desired_count
      platform_version = aws_ecs_service.backend.platform_version
      launch_type     = "FARGATE"
      load_balancer_integrated = true
    }
  }
}

# TROUBLESHOOTING INFORMATION
output "troubleshooting_commands" {
  description = "Useful AWS CLI commands for troubleshooting"
  value = {
    list_tasks = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name}"
    describe_tasks = "aws ecs describe-tasks --cluster ${aws_ecs_cluster.main.name} --tasks TASK_ARN"
    view_logs = "aws logs tail /aws/ecs/${var.name_prefix} --follow"
    service_events = "aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.frontend.name}"
    task_definition = "aws ecs describe-task-definition --task-definition ${aws_ecs_task_definition.frontend.family}"
  }
}

# INTEGRATION INFORMATION
output "load_balancer_integration" {
  description = "Load balancer integration details"
  value = {
    target_group_arn = var.target_group_arn
    container_port   = var.container_port
    health_check_grace_period = var.health_check_grace_period
  }
}

output "database_integration" {
  description = "Database integration details"
  value = {
    host_endpoint = var.db_host
    secrets_arn   = var.db_secret_arn
    connection_port = 5432
  }
  sensitive = true
}

# COST OPTIMIZATION INFORMATION
output "cost_optimization_tips" {
  description = "Tips for optimizing ECS costs"
  value = {
    current_config = "CPU: ${var.container_cpu}, Memory: ${var.container_memory}MB, Count: ${var.desired_count}"
    cost_per_hour = format("$%.4f", ((var.container_cpu / 1024) * 0.04048) + ((var.container_memory / 1024) * 0.004445))
    monthly_estimate = format("$%.2f", (((var.container_cpu / 1024) * 0.04048) + ((var.container_memory / 1024) * 0.004445)) * 24 * 30 * var.desired_count * 2)
    tips = [
      "Right-size containers based on actual CPU/memory usage",
      "Use Fargate Spot for non-critical workloads (up to 70% savings)",
      "Enable auto-scaling to scale down during low traffic",
      "Monitor Container Insights for optimization opportunities",
      "Consider scheduled scaling for predictable traffic patterns"
    ]
  }
}