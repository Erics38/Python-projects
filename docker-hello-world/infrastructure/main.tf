# Terraform configuration for Guestbook Application
# Professional-grade infrastructure with ECS Fargate, RDS, and ALB

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"  # Pinned to stable version with known compatibility
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Remote state backend - configured after running backend setup
  # To enable remote state:
  # 1. cd backend && terraform apply
  # 2. Copy backend configuration from output
  # 3. Uncomment and update the backend block below
  # 4. Run: terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket         = "guestbook-terraform-state-XXXX"
  #   key            = "guestbook/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "guestbook-terraform-locks"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Guestbook"
      Environment = var.environment
      Owner       = "Demo"
      ManagedBy   = "Terraform"
      Repository  = "docker-hello-world"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Local values for resource naming
locals {
  name_prefix = "guestbook-${var.environment}"
  
  # Network configuration - SIMPLIFIED FOR DEMO
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 1)  # Single AZ for demo
  
  # Container configuration
  container_port = 3000
  
  # Common tags
  common_tags = {
    Project     = "Guestbook"
    Environment = var.environment
    Owner       = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Networking
module "networking" {
  source = "./modules/networking"
  
  name_prefix = local.name_prefix
  vpc_cidr    = local.vpc_cidr
  azs         = local.azs
  tags        = local.common_tags
}

# Security
module "security" {
  source = "./modules/security"
  
  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = local.vpc_cidr
  tags        = local.common_tags
}

# Database
module "database" {
  source = "./modules/database"
  
  name_prefix          = local.name_prefix
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  database_sg_id      = module.security.database_sg_id
  db_password         = random_password.db_password.result
  environment         = var.environment
  tags                = local.common_tags
}

# Load Balancer
module "load_balancer" {
  source = "./modules/load_balancer"
  
  name_prefix        = local.name_prefix
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  domain_name       = var.domain_name
  tags              = local.common_tags
}

# ECS Cluster and Services
module "ecs" {
  source = "./modules/ecs"
  
  name_prefix         = local.name_prefix
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ecs_sg_id          = module.security.ecs_sg_id
  target_group_arn   = module.load_balancer.target_group_arn
  
  # Database connection
  db_host       = module.database.db_endpoint
  db_secret_arn = aws_secretsmanager_secret.db_credentials.arn
  
  # Container images
  frontend_image = var.frontend_image
  backend_image  = var.backend_image
  
  # Configuration
  container_port = local.container_port
  environment    = var.environment
  tags           = local.common_tags
}

# Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials for guestbook application"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db_password.result
    host     = module.database.db_endpoint
    port     = 5432
    dbname   = "guestbook_db"
  })
}

# Comprehensive Monitoring and Alerting
module "monitoring" {
  source = "./modules/monitoring"
  
  environment               = var.environment
  aws_region               = var.aws_region
  cluster_name             = module.ecs.cluster_name
  frontend_service_name    = module.ecs.frontend_service_name
  backend_service_name     = module.ecs.backend_service_name
  database_identifier      = module.database.db_instance_id
  load_balancer_arn_suffix = module.load_balancer.arn_suffix
  
  # Monitoring configuration
  log_retention_days       = var.log_retention_days
  alert_email             = var.alert_email
  enable_container_insights = var.enable_container_insights
  cpu_alarm_threshold     = var.cpu_alarm_threshold
  memory_alarm_threshold  = var.memory_alarm_threshold
  response_time_threshold = var.response_time_threshold
}

# Security Hardening (WAF, HTTPS, Security Headers) - DISABLED FOR DEMO
# Uncomment when ready for production deployment
# module "security_hardening" {
#   source = "./modules/security_hardening"
#   
#   environment         = var.environment
#   aws_region         = var.aws_region
#   load_balancer_arn  = module.load_balancer.arn
#   
#   # Security configuration
#   enable_https                    = var.enable_https
#   domain_name                    = var.domain_name
#   enable_security_headers        = var.enable_security_headers
#   rate_limit_per_5min           = var.rate_limit_per_5min
#   blocked_countries             = var.blocked_countries
#   allowed_ips                   = var.allowed_ips
#   waf_blocked_requests_threshold = var.waf_blocked_requests_threshold
#   
#   # Integration with monitoring
#   sns_topic_arn      = module.monitoring.sns_topic_arn
#   log_retention_days = var.log_retention_days
# }