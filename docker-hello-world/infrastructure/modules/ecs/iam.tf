# IAM Roles and Policies for ECS
# TEACHING POINT: Two Different Roles Needed
# 1. Execution Role: Used by ECS agent to set up your container
# 2. Task Role: Used by your application code to access AWS services

# ==============================================================================
# ECS EXECUTION ROLE
# ==============================================================================
# This role is used BY ECS (not by your app) to:
# - Pull container images from ECR
# - Create CloudWatch log groups and streams  
# - Retrieve secrets from Secrets Manager/Parameter Store
# - Set up networking and storage

resource "aws_iam_role" "ecs_execution_role" {
  name_prefix = "${var.name_prefix}-ecs-execution-"
  description = "Role used by ECS to execute tasks (pull images, setup logs, etc.)"
  
  # TRUST POLICY: Who can "assume" (use) this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"  # Only ECS can use this role
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.name_prefix}-ecs-execution-role"
    Environment = var.environment
    ManagedBy = "Terraform"
  }
}

# ATTACH AWS MANAGED POLICY: Basic ECS execution permissions
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CUSTOM POLICY: Additional permissions for our specific needs
resource "aws_iam_role_policy" "ecs_execution_custom_policy" {
  name_prefix = "${var.name_prefix}-ecs-execution-custom-"
  role        = aws_iam_role.ecs_execution_role.id
  
  # PERMISSIONS POLICY: What actions this role can perform
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # SECRETS MANAGER: Read database credentials
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.db_secret_arn,
          "${var.db_secret_arn}:*"  # Include version ARNs
        ]
      },
      {
        # KMS: Decrypt secrets (Secrets Manager uses KMS encryption)
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"  # Could be more restrictive with specific KMS key ARN
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        # PARAMETER STORE: Read configuration parameters (if used)
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/*",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/guestbook-*"
        ]
      },
      {
        # ECR: Enhanced permissions for private repositories
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"  # ECR GetAuthorizationToken requires * resource
      }
    ]
  })
}

# ==============================================================================
# ECS TASK ROLE
# ==============================================================================
# This role is used BY YOUR APPLICATION CODE to access other AWS services
# Examples: S3 buckets, DynamoDB tables, SQS queues, SNS topics, etc.

resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "${var.name_prefix}-ecs-task-"
  description = "Role used by application code running in ECS containers"
  
  # TRUST POLICY: Allow ECS tasks to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.name_prefix}-ecs-task-role"
    Environment = var.environment
    ManagedBy = "Terraform"
  }
}

# APPLICATION-SPECIFIC PERMISSIONS
resource "aws_iam_role_policy" "ecs_task_custom_policy" {
  name_prefix = "${var.name_prefix}-ecs-task-custom-"
  role        = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # CLOUDWATCH LOGS: Application can write custom logs
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${var.name_prefix}:*"
      },
      {
        # SES: Send email notifications (from your existing Lambda function)
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"  # SES permissions are typically account-wide
      },
      {
        # SQS: Send messages to notification queue
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:guestbook-notifications"
      },
      {
        # SECRETS MANAGER: Application can read its own secrets
        # This allows your app to refresh database credentials periodically
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      },
      {
        # X-RAY: Distributed tracing (optional but good for production)
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# AUTO SCALING ROLE (if auto-scaling is enabled)
# ==============================================================================
# This role allows ECS to automatically scale your services up/down
# based on CPU, memory, or custom metrics

resource "aws_iam_role" "ecs_autoscaling_role" {
  count       = var.enable_autoscaling ? 1 : 0
  name_prefix = "${var.name_prefix}-ecs-autoscaling-"
  description = "Role for ECS service auto-scaling operations"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.name_prefix}-ecs-autoscaling-role"
    Environment = var.environment
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_role_policy" {
  count      = var.enable_autoscaling ? 1 : 0
  role       = aws_iam_role.ecs_autoscaling_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
}

# ==============================================================================
# TEACHING POINTS ABOUT IAM ROLES
# ==============================================================================
# 
# WHY TWO ROLES?
# Execution Role = "Infrastructure" operations (managed by AWS ECS)
# Task Role = "Application" operations (managed by your code)
#
# SECURITY PRINCIPLE: Least Privilege
# Each role gets only the minimum permissions needed for its job
#
# BEST PRACTICES:
# 1. Never use * for Resource unless absolutely necessary
# 2. Use Condition blocks to further restrict access
# 3. Regularly audit and remove unused permissions
# 4. Use AWS managed policies when available
# 5. Create custom policies for application-specific needs
#
# DEBUGGING IAM ISSUES:
# 1. Check CloudTrail logs for denied API calls
# 2. Use IAM Policy Simulator to test permissions
# 3. Enable CloudWatch Logs for ECS agent
# 4. Verify trust relationships (who can assume the role)
#
# COST IMPLICATIONS:
# IAM roles and policies are free, but:
# - CloudWatch Logs storage has costs
# - Secrets Manager charges per secret per month
# - KMS key usage has small per-operation costs