# Terraform Variables for Guestbook Demo
# Basic configuration for testing

aws_region = "us-east-1"
environment = "demo"

# Container images (using simple images for testing)
frontend_image = "nginx:alpine"
backend_image = "node:18-alpine"

# Minimal resources for cost savings
container_cpu = 256
container_memory = 512
desired_count = 1

# Database settings
instance_class = "db.t3.micro"
allocated_storage = 20
backup_retention_period = 7
multi_az = false
enable_deletion_protection = false
enable_performance_insights = false

# Monitoring
log_retention_days = 7

# Scaling (disabled for demo)
enable_autoscaling = false
min_capacity = 1
max_capacity = 3

# Health checks
health_check_grace_period = 60