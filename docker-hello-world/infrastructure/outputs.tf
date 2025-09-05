# Outputs for Guestbook Infrastructure

# Application URLs
output "application_url" {
  description = "URL of the application load balancer"
  value       = "https://${module.load_balancer.dns_name}"
}

output "load_balancer_dns" {
  description = "DNS name of the application load balancer"
  value       = module.load_balancer.dns_name
}

output "load_balancer_hosted_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = module.load_balancer.hosted_zone_id
}

# Networking
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = local.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# Database
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

# ECS
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = module.ecs.frontend_service_name
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = module.ecs.backend_service_name
}

# Security
output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = module.security.alb_sg_id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = module.security.ecs_sg_id
}

output "database_security_group_id" {
  description = "Security group ID for the database"
  value       = module.security.database_sg_id
}

# Secrets
output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

# Monitoring and CloudWatch
output "monitoring_dashboard_url" {
  description = "URL of the CloudWatch monitoring dashboard"
  value       = module.monitoring.cloudwatch_dashboard_url
}

output "monitoring_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

output "monitoring_log_group" {
  description = "Name of the application CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "alerts_sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "monitoring_alarms" {
  description = "List of CloudWatch alarm names"
  value       = module.monitoring.alarm_names
}

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value       = module.monitoring.monitoring_summary
}

# Security and Hardening
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.security_hardening.waf_web_acl_arn
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.security_hardening.ssl_certificate_arn
}

output "security_features_summary" {
  description = "Summary of security features enabled"
  value       = module.security_hardening.security_features_summary
}

output "waf_rules_summary" {
  description = "Summary of WAF rules configured"
  value       = module.security_hardening.waf_rules_summary
}

# Cost Estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    fargate_tasks = "~$${(var.container_cpu / 1024) * 0.04048 * 24 * 30 * var.desired_count * 2} (2 services)"
    rds_instance  = var.instance_class == "db.t3.micro" ? "~$15.00" : "~$30-100+"
    load_balancer = "~$20.00"
    data_transfer = "~$5-15 (estimated)"
    cloudwatch    = "~$3-10 (estimated)"
    total         = "~$${43 + (var.container_cpu / 1024) * 0.04048 * 24 * 30 * var.desired_count * 2}-${88 + (var.container_cpu / 1024) * 0.04048 * 24 * 30 * var.desired_count * 2}"
  }
}

# Environment Information
output "environment_info" {
  description = "Environment configuration summary"
  value = {
    environment     = var.environment
    region         = var.aws_region
    container_cpu  = "${var.container_cpu} (${var.container_cpu / 1024} vCPU)"
    container_memory = "${var.container_memory} MB"
    desired_count  = var.desired_count
    database_class = var.instance_class
    multi_az       = var.multi_az
    backup_retention = "${var.backup_retention_period} days"
  }
}

# Resource Tags
output "resource_tags" {
  description = "Common resource tags applied to all resources"
  value       = local.common_tags
}