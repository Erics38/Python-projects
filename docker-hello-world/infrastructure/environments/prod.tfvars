# Production Environment Configuration
# Optimized for high availability, performance, and reliability

# Basic Configuration
aws_region  = "us-east-1"
environment = "prod"

# Container Configuration (Production Sized)
container_cpu    = 1024  # 1 vCPU (production performance)
container_memory = 2048  # 2GB RAM (production capacity)
desired_count    = 2     # Multiple instances (high availability)

# Database Configuration (Production Grade)
instance_class                = "db.t3.medium"          # Production instance size
allocated_storage            = 50                       # More storage
backup_retention_period      = 30                       # Extended backup retention
multi_az                     = true                     # High availability (automatic failover)
enable_deletion_protection   = true                     # Prevent accidental deletion
enable_performance_insights  = true                     # Production monitoring
publicly_accessible         = false                    # Security requirement

# Scaling (Production Auto-scaling)
enable_autoscaling = true   # Handle traffic spikes
min_capacity      = 2       # Always maintain 2 instances
max_capacity      = 10      # Scale up to 10 instances
cpu_target_value  = 70      # Scale when CPU > 70%
memory_target_value = 80    # Scale when memory > 80%

# Monitoring and Alerting (Production Grade)
log_retention_days         = 365   # One year retention for compliance
alert_email               = ""     # REQUIRED: Add operations team email for production
enable_container_insights = true   # Full monitoring enabled
cpu_alarm_threshold       = 70     # Aggressive threshold for production
memory_alarm_threshold    = 75     # Aggressive threshold for production
response_time_threshold   = 1.0    # Strict performance requirements

# Security Hardening (Production Grade)
enable_https                    = true        # REQUIRED: Enable HTTPS for production
domain_name                    = ""           # REQUIRED: Add production domain
enable_security_headers        = true         # Full security headers suite
rate_limit_per_5min           = 1000         # Production rate limiting
blocked_countries             = []           # Optional: block high-risk countries
allowed_ips                   = []           # Optional: corporate IP whitelist
waf_blocked_requests_threshold = 100         # Low threshold for production alerts

# Deployment Configuration (Zero Downtime)
health_check_grace_period           = 120  # More time for production startup
deployment_maximum_percent          = 200  # Maintain capacity during deployment
deployment_minimum_healthy_percent  = 100  # Zero downtime deployments

# Production-Specific Notes:
# - Total estimated cost: ~$200-400/month (depending on traffic)
# - High availability with automatic failover
# - Zero-downtime deployments
# - Extended monitoring and backup retention
# - Auto-scaling for traffic spikes
# - Deletion protection enabled
# - Compliant with most enterprise requirements