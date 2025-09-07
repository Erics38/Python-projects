# MINIMAL WORKING CONFIGURATION
aws_region = "us-east-1"
environment = "demo"

# Use simple public images that definitely work
frontend_image = "nginx:latest"
backend_image = "httpd:latest"

# Minimal resources
container_cpu = 256
container_memory = 512
desired_count = 1
container_port = 80

# Minimal database
instance_class = "db.t3.micro"
allocated_storage = 20
backup_retention_period = 1
multi_az = false
enable_deletion_protection = false

# Minimal monitoring
log_retention_days = 1
enable_autoscaling = false