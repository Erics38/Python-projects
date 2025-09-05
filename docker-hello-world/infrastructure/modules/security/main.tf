# Security Module
# Creates security groups following the principle of least privilege
# Implements defense-in-depth with multiple layers of security

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # Allow HTTP traffic from anywhere (will redirect to HTTPS)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic to ECS - defined as separate rule to avoid circular dependency

  # Allow outbound HTTPS for health checks and AWS API calls
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
    Type = "Security Group"
    Purpose = "Application Load Balancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs" {
  name_prefix = "${var.name_prefix}-ecs-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS tasks"

  # Traffic from ALB - defined as separate rule to avoid circular dependency

  # Allow communication between ECS tasks (for service mesh, logging, etc.)
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound traffic for:
  # - Database connections
  # - ECR image pulls
  # - CloudWatch logs
  # - Parameter Store/Secrets Manager
  # - External API calls
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-sg"
    Type = "Security Group"
    Purpose = "ECS Tasks"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS database"

  # Only allow PostgreSQL connections from ECS tasks
  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  # Allow connections from within the VPC for maintenance/debugging (optional)
  ingress {
    description = "PostgreSQL from VPC (maintenance)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # No outbound rules needed for RDS (AWS manages this)
  # But we'll add minimal rules for security best practices
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-sg"
    Type = "Security Group"
    Purpose = "RDS Database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Additional security group for bastion host (optional, for debugging)
resource "aws_security_group" "bastion" {
  name_prefix = "${var.name_prefix}-bastion-"
  vpc_id      = var.vpc_id
  description = "Security group for bastion host (debugging only)"

  # SSH access from specific IPs only (replace with your IP)
  ingress {
    description = "SSH from trusted IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SECURITY: Replace with your specific IP
  }

  # Allow outbound traffic for package updates and AWS CLI
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
    Type = "Security Group"
    Purpose = "Bastion Host (Debugging)"
    Warning = "Only use for debugging, remove in production"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# WAF Security Group for additional protection (optional)
resource "aws_security_group" "waf" {
  name_prefix = "${var.name_prefix}-waf-"
  vpc_id      = var.vpc_id
  description = "Security group for WAF-protected resources"

  # This will be used later when we add WAF
  # For now, it's a placeholder for future security enhancements

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-waf-sg"
    Type = "Security Group"
    Purpose = "WAF Protection (Future Use)"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group rules for monitoring and logging
resource "aws_security_group_rule" "ecs_aws_apis" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "AWS APIs access - CloudWatch Logs, Parameter Store, Secrets Manager"

  security_group_id = aws_security_group.ecs.id
}

# KMS access for secrets decryption
resource "aws_security_group_rule" "ecs_kms" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "KMS API access for secrets decryption"

  security_group_id = aws_security_group.ecs.id
}

# Separate rules to avoid circular dependencies between ALB and ECS security groups

# Allow ALB to send traffic to ECS tasks
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.alb.id
  description              = "HTTP to ECS tasks"
}

# Allow ECS tasks to receive traffic from ALB
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "HTTP from ALB"
}