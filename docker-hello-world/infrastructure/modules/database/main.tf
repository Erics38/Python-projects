# Database Module
# Creates RDS PostgreSQL instance with production-ready configurations
# Includes automated backups, monitoring, and security best practices

# TEACHING POINT: DB Subnet Groups
# RDS requires a DB subnet group that defines which subnets the database can use
# This must span at least 2 AZs for high availability and is required for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  description = "Subnet group for RDS database - spans multiple AZs for HA"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
    Purpose = "Database network isolation"
  })
}

# TEACHING POINT: Parameter Groups
# Parameter groups allow you to customize database configuration
# This creates a custom parameter group based on PostgreSQL defaults
# but allows for future customization without modifying the default
resource "aws_db_parameter_group" "main" {
  family      = "postgres15"  # Must match your PostgreSQL major version
  name_prefix = "${var.name_prefix}-db-params-"
  description = "Custom parameter group for guestbook PostgreSQL database"

  # SIMPLIFIED PARAMETERS FOR DEMO - Only dynamic parameters
  parameter {
    name  = "log_statement"
    value = "all"  # Log all SQL statements (disable in production for performance)
    apply_method = "immediate"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking longer than 1 second
    apply_method = "immediate"
  }

  # CONNECTION MANAGEMENT: Adjust based on expected connection load
  parameter {
    name  = "max_connections"
    value = "100"  # Default is usually fine for small applications
    apply_method = "pending-reboot"  # This parameter requires restart
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-parameter-group"
    Type = "DB Parameter Group"
    Purpose = "Database configuration management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# TEACHING POINT: RDS Instance Configuration
# This is the main database instance with production-ready settings
resource "aws_db_instance" "main" {
  # BASIC CONFIGURATION
  identifier = "${var.name_prefix}-db"  # Must be unique within AWS account
  
  # ENGINE CONFIGURATION
  engine         = "postgres"
  engine_version = "15.7"  # Always specify exact version for reproducibility
  instance_class = var.instance_class  # Size of the database server (CPU/RAM)
  
  # STORAGE CONFIGURATION
  allocated_storage     = var.allocated_storage  # Initial storage in GB
  max_allocated_storage = var.allocated_storage * 2  # Auto-scaling upper limit
  storage_type          = "gp3"  # General Purpose SSD (gp3 is latest, faster than gp2)
  storage_encrypted     = true   # Always encrypt data at rest
  
  # DATABASE CREDENTIALS
  # SECURITY NOTE: Never put passwords in plain text in Terraform
  db_name  = "guestbook_db"
  username = "app_user"
  password = var.db_password  # Passed from random_password resource
  
  # NETWORKING AND SECURITY
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_sg_id]
  publicly_accessible    = var.publicly_accessible  # Should be false for security
  port                   = 5432  # Standard PostgreSQL port
  
  # HIGH AVAILABILITY AND BACKUP
  multi_az               = var.multi_az  # Deploy across multiple AZs (costs more)
  backup_retention_period = var.backup_retention_period  # Days to keep backups
  backup_window          = "03:00-04:00"  # UTC time window for automated backups
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC window for maintenance
  
  # ADVANCED CONFIGURATION
  parameter_group_name = aws_db_parameter_group.main.name
  copy_tags_to_snapshot = true  # Copy tags to automated snapshots
  
  # DELETION PROTECTION
  deletion_protection = var.enable_deletion_protection  # Prevent accidental deletion
  skip_final_snapshot = !var.enable_deletion_protection  # Take final snapshot if protection enabled
  final_snapshot_identifier = var.enable_deletion_protection ? "${var.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  # MONITORING AND PERFORMANCE
  monitoring_interval = 60  # Enhanced monitoring every 60 seconds
  monitoring_role_arn = var.enable_performance_insights ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  performance_insights_enabled = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? 7 : null  # Days to retain PI data
  
  # LOGGING: Enable all PostgreSQL logs for debugging
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # AUTOMATIC VERSION UPGRADES
  auto_minor_version_upgrade = true  # Allow automatic minor version updates
  allow_major_version_upgrade = false  # Require manual approval for major updates
  
  # SECURITY: Apply updates immediately during maintenance window
  apply_immediately = false  # Changes applied during maintenance window
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database"
    Type = "RDS Instance"
    Engine = "PostgreSQL"
    Environment = var.environment
    Purpose = "Application database with automated backups and monitoring"
  })
  
  # LIFECYCLE MANAGEMENT
  lifecycle {
    # Prevent accidental recreation due to password changes
    ignore_changes = [password]
    
    # Don't delete the database if someone removes it from Terraform
    prevent_destroy = false  # Set to true for production
  }
  
  # DEPENDENCIES: Ensure networking is ready before creating database
  depends_on = [
    aws_db_subnet_group.main,
    aws_db_parameter_group.main
  ]
}

# TEACHING POINT: IAM Role for Enhanced Monitoring
# RDS Enhanced Monitoring requires an IAM role to publish metrics to CloudWatch
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enable_performance_insights ? 1 : 0
  
  name_prefix = "${var.name_prefix}-rds-monitoring-"
  description = "IAM role for RDS Enhanced Monitoring"
  
  # TRUST POLICY: Allow RDS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-monitoring-role"
    Type = "IAM Role"
    Purpose = "RDS Enhanced Monitoring"
  })
}

# ATTACH AWS MANAGED POLICY: Provides necessary permissions for enhanced monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.enable_performance_insights ? 1 : 0
  
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# TEACHING POINT: CloudWatch Alarms for Database Monitoring
# These alarms will notify you of database performance issues

# DATABASE CONNECTION ALARM: Alert when connection count is high
resource "aws_cloudwatch_metric_alarm" "database_connection_count" {
  alarm_name          = "${var.name_prefix}-db-connection-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"  # Alert after 2 consecutive periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"  # 5-minute periods
  statistic           = "Average"
  threshold           = "80"   # Alert when average connections > 80
  alarm_description   = "This metric monitors RDS database connection count"
  alarm_actions       = []     # TODO: Add SNS topic for notifications
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-connection-alarm"
    Type = "CloudWatch Alarm"
    Purpose = "Database connection monitoring"
  })
}

# CPU UTILIZATION ALARM: Alert when CPU usage is consistently high
resource "aws_cloudwatch_metric_alarm" "database_cpu_utilization" {
  alarm_name          = "${var.name_prefix}-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"  # Alert when CPU > 75% for 10 minutes
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = []    # TODO: Add SNS topic for notifications
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-cpu-alarm"
    Type = "CloudWatch Alarm"
    Purpose = "Database CPU monitoring"
  })
}

# FREE STORAGE SPACE ALARM: Alert when storage is running low
resource "aws_cloudwatch_metric_alarm" "database_free_storage_space" {
  alarm_name          = "${var.name_prefix}-db-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000000000"  # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = []            # TODO: Add SNS topic for notifications
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-storage-alarm"
    Type = "CloudWatch Alarm"
    Purpose = "Database storage monitoring"
  })
}