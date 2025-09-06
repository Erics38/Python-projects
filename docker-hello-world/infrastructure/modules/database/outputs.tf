# Database Module Outputs
# These outputs provide connection details and resource information
# to other modules and for external reference

# PRIMARY CONNECTION DETAILS
# These are used by the ECS module to connect to the database
output "db_endpoint" {
  description = "RDS instance connection endpoint (hostname)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # Mark as sensitive to avoid displaying in logs
  
  # TEACHING POINT: Database endpoints look like:
  # myapp-db.c1234567890.us-east-1.rds.amazonaws.com
}

output "db_port" {
  description = "Database connection port"
  value       = aws_db_instance.main.port
  
  # Standard PostgreSQL port is 5432
  # This output allows flexibility if port changes in future
}

output "db_name" {
  description = "Name of the initial database created"
  value       = aws_db_instance.main.db_name
  
  # This is the database name your application connects to
  # Additional databases can be created within this instance
}

output "db_username" {
  description = "Master username for database access"
  value       = aws_db_instance.main.username
  sensitive   = true
  
  # SECURITY NOTE: This is the master user, not the application user
  # In production, create separate users with limited privileges
}

# INFRASTRUCTURE DETAILS
output "db_instance_id" {
  description = "RDS instance identifier for AWS CLI and API operations"
  value       = aws_db_instance.main.id
  
  # Used for operations like:
  # aws rds describe-db-instances --db-instance-identifier <this-value>
}

output "db_arn" {
  description = "Amazon Resource Name (ARN) of the RDS instance"
  value       = aws_db_instance.main.arn
  
  # ARNs are used for IAM policies and cross-service references
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
  
  # Useful for creating additional databases in the same subnet group
}

output "db_parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
  
  # Parameter groups can be shared across multiple database instances
}

# MONITORING AND MANAGEMENT
output "db_cloudwatch_log_groups" {
  description = "CloudWatch log groups for database logs"
  value = {
    postgresql = "/aws/rds/instance/${aws_db_instance.main.id}/postgresql"
  }
  
  # These log groups contain database logs for debugging and monitoring
  # Access with: aws logs tail /aws/rds/instance/mydb/postgresql
}

output "monitoring_role_arn" {
  description = "ARN of the IAM role used for enhanced monitoring"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
  
  # This role allows RDS to publish detailed metrics to CloudWatch
}

# OPERATIONAL INFORMATION
output "backup_window" {
  description = "Daily time range during which automated backups are created"
  value       = aws_db_instance.main.backup_window
  
  # IMPORTANT: Plan application maintenance around this window
  # Database performance may be impacted during backups
}

output "maintenance_window" {
  description = "Weekly time range during which system maintenance can occur"
  value       = aws_db_instance.main.maintenance_window
  
  # AWS may perform updates, patches, or scaling during this window
  # Choose a time when your application has lowest usage
}

output "backup_retention_period" {
  description = "Number of days automated backups are retained"
  value       = aws_db_instance.main.backup_retention_period
  
  # Used for point-in-time recovery and compliance reporting
}

# SECURITY INFORMATION
output "encryption_enabled" {
  description = "Whether the database storage is encrypted"
  value       = aws_db_instance.main.storage_encrypted
  
  # Should always be true for production workloads
}

output "multi_az_enabled" {
  description = "Whether Multi-AZ deployment is enabled"
  value       = aws_db_instance.main.multi_az
  
  # Multi-AZ provides automatic failover and higher availability
}

# COST TRACKING
output "instance_class" {
  description = "Database instance class (for cost tracking)"
  value       = aws_db_instance.main.instance_class
  
  # Helps track costs and plan capacity upgrades
}

output "allocated_storage" {
  description = "Amount of storage allocated to the database in GB"
  value       = aws_db_instance.main.allocated_storage
  
  # Storage costs scale with this value
  # Monitor actual usage vs allocated storage
}

# CONNECTION STRING TEMPLATE
output "connection_info" {
  description = "Database connection information for applications"
  value = {
    # JDBC URL format for Java applications
    jdbc_url = "jdbc:postgresql://${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
    
    # Node.js connection object format
    node_config = {
      host     = aws_db_instance.main.endpoint
      port     = aws_db_instance.main.port
      database = aws_db_instance.main.db_name
      username = aws_db_instance.main.username
      # password should come from AWS Secrets Manager, not hardcoded
    }
    
    # Environment variables format (common for containerized apps)
    env_vars = {
      DB_HOST     = aws_db_instance.main.endpoint
      DB_PORT     = aws_db_instance.main.port
      DB_NAME     = aws_db_instance.main.db_name
      DB_USERNAME = aws_db_instance.main.username
      # DB_PASSWORD should come from secrets management
    }
  }
  sensitive = true
  
  # SECURITY REMINDER: Never log or display actual passwords
  # Always use AWS Secrets Manager or similar for password management
}

# CLOUDWATCH ALARM ARNS
output "cloudwatch_alarms" {
  description = "ARNs of CloudWatch alarms created for database monitoring"
  value = {
    connection_count   = aws_cloudwatch_metric_alarm.database_connection_count.arn
    cpu_utilization   = aws_cloudwatch_metric_alarm.database_cpu_utilization.arn
    free_storage_space = aws_cloudwatch_metric_alarm.database_free_storage_space.arn
  }
  
  # These can be used to set up SNS notifications or integrate with monitoring systems
}