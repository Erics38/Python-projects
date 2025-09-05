# Development Environment Configuration
# Balanced between cost and development productivity

# Basic Configuration
aws_region  = "us-east-1"
environment = "dev"

# Container Configuration (Slightly Higher for Development)
container_cpu    = 512   # 0.5 vCPU (better performance for development)
container_memory = 1024  # 1GB RAM (comfortable for debugging)
desired_count    = 1     # Single instance for development

# Database Configuration (Development Optimized)
instance_class                = "db.t3.small"           # More resources for development
allocated_storage            = 20                       # Standard storage
backup_retention_period      = 3                        # Minimal backups for dev
multi_az                     = false                    # Single AZ (cost optimization)
enable_deletion_protection   = false                    # Allow easy recreation
enable_performance_insights  = true                     # Enable for development debugging
publicly_accessible         = false                    # Security best practice

# Scaling (Limited for Development)
enable_autoscaling = false  # Predictable behavior for development
min_capacity      = 1
max_capacity      = 2

# Monitoring and Alerting (Development Focused)
log_retention_days         = 14    # Two weeks for debugging
alert_email               = ""     # Optional: add developer email for alerts
enable_container_insights = true   # Full monitoring for development
cpu_alarm_threshold       = 75     # Lower threshold for early detection
memory_alarm_threshold    = 80     # Lower threshold for performance analysis
response_time_threshold   = 2.0    # Stricter performance requirements

# Security Hardening (Development)
enable_https                    = false       # Optional: set to true with custom domain
domain_name                    = ""           # Optional: add development domain
enable_security_headers        = true         # Full security headers for testing
rate_limit_per_5min           = 1500         # Moderate rate limiting
blocked_countries             = []           # No geo-blocking for development
allowed_ips                   = []           # Optional: restrict to office IPs
waf_blocked_requests_threshold = 150         # Moderate threshold for development

# Deployment Configuration (Developer Friendly)
health_check_grace_period           = 90   # More time for debugging
deployment_maximum_percent          = 200  # Fast deployments
deployment_minimum_healthy_percent  = 0    # Allow full replacement for faster deployments

# Development-Specific Notes:
# - Total estimated cost: ~$70-80/month
# - Performance Insights enabled for query debugging
# - Faster deployments at cost of brief downtime
# - More resources for comfortable development experience