# Demo Environment Configuration
# Optimized for cost-effective demonstrations and learning

# Basic Configuration
aws_region  = "us-east-1"
environment = "demo"

# Container Configuration
container_cpu    = 256   # 0.25 vCPU (minimal for demo)
container_memory = 512   # 512MB RAM (sufficient for demo apps)
desired_count    = 1     # Single instance (cost optimization)

# Database Configuration (Cost Optimized)
instance_class                = "db.t3.micro"           # Free tier eligible
allocated_storage            = 20                       # Minimum storage
backup_retention_period      = 7                        # Short retention
multi_az                     = false                    # Single AZ (50% cost savings)
enable_deletion_protection   = false                    # Allow easy cleanup
enable_performance_insights  = false                    # Avoid additional costs
publicly_accessible         = false                    # Security best practice

# Scaling (Disabled for Cost Control)
enable_autoscaling = false
min_capacity      = 1
max_capacity      = 3

# Monitoring and Alerting (Cost Optimized)
log_retention_days         = 7     # Short log retention for cost savings
alert_email               = ""     # No email alerts for demo (optional)
enable_container_insights = true   # Enable for demo purposes
cpu_alarm_threshold       = 85     # Higher threshold for cost optimization
memory_alarm_threshold    = 90     # Higher threshold for cost optimization
response_time_threshold   = 3.0    # Relaxed for demo environment

# Security Hardening variables removed - module disabled for demo
# These will be restored when security_hardening module is re-enabled

# Deployment Configuration
health_check_grace_period           = 60
deployment_maximum_percent          = 200  # Allow 2x instances during deployment
deployment_minimum_healthy_percent  = 50   # Allow some downtime for cost savings

# Demo-Specific Notes:
# - Total estimated cost: ~$50-60/month when running
# - Can be stopped completely to reduce to ~$0/month
# - Optimized for learning and demonstration, not production workloads
# - No high availability (single AZ, single instance)