# Demo-Only Configuration - Simplified Variables
# Only includes variables actually used by enabled modules

# Basic Configuration
aws_region  = "us-east-1"
environment = "demo"

# Container Configuration
container_cpu    = 256
container_memory = 512
desired_count    = 1

# Database Configuration
instance_class                = "db.t3.micro"
allocated_storage            = 20
backup_retention_period      = 7
multi_az                     = false
enable_deletion_protection   = false
enable_performance_insights  = false
publicly_accessible         = false

# Scaling (Disabled)
enable_autoscaling = false
min_capacity      = 1
max_capacity      = 3

# Monitoring
log_retention_days         = 7
alert_email               = ""
enable_container_insights = true
cpu_alarm_threshold       = 85
memory_alarm_threshold    = 90
response_time_threshold   = 3.0

# Deployment Configuration
health_check_grace_period           = 60
deployment_maximum_percent          = 200
deployment_minimum_healthy_percent  = 50

# Container Images (using defaults)
frontend_image = "nginx:alpine"
backend_image  = "node:18-alpine"