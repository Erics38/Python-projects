# ECS (Elastic Container Service) Module
# This is the heart of our containerized application infrastructure
# ECS Fargate = Serverless containers (no EC2 instances to manage)

# TEACHING POINT: ECS Cluster
# A cluster is a logical grouping of compute resources
# Think of it as a "container orchestration environment"
# Fargate clusters are just logical constructs - no actual servers

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"
  
  # CLUSTER CONFIGURATION
  # These settings apply to the entire cluster
  setting {
    name  = "containerInsights"  # Enable detailed monitoring
    value = "enabled"            # Provides container-level metrics in CloudWatch
  }
  
  # Basic ECS cluster configuration
  # Capacity providers will be configured separately
  
  # OPTIONAL: Use Fargate Spot for cost savings (up to 70% cheaper)
  # Spot instances can be interrupted, so only use for fault-tolerant workloads
  # default_capacity_provider_strategy {
  #   capacity_provider = "FARGATE_SPOT"
  #   weight            = 0              # 0% by default, can override per service
  #   base              = 0
  # }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-cluster"
    Type = "ECS Cluster"
    Purpose = "Container orchestration for web application"
  })
}

# CAPACITY PROVIDERS: Configure how containers get compute resources
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# TEACHING POINT: Task Definition
# A task definition is like a "blueprint" for your containers
# It defines: CPU, memory, network, storage, environment variables, etc.
# Think of it as a "Docker Compose file" for AWS

resource "aws_ecs_task_definition" "frontend" {
  family = "${var.name_prefix}-frontend"  # Name family (versions get appended)
  
  # FARGATE REQUIREMENTS
  requires_compatibilities = ["FARGATE"]     # This task runs on Fargate
  network_mode            = "awsvpc"        # Each task gets its own network interface
  cpu                     = var.container_cpu     # CPU units (1024 = 1 vCPU)
  memory                  = var.container_memory  # Memory in MB
  
  # EXECUTION ROLE: Allows ECS to pull images, create logs, etc.
  # This is the role ECS agent uses, NOT your application
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  
  # TASK ROLE: The role your application code runs with
  # Use this for accessing other AWS services (S3, DynamoDB, etc.)
  task_role_arn = aws_iam_role.ecs_task_role.arn
  
  # CONTAINER DEFINITIONS (JSON format required by AWS)
  # This defines all containers that run together as a "task"
  container_definitions = jsonencode([
    {
      # BASIC CONTAINER CONFIG
      name      = "frontend"
      image     = var.frontend_image
      essential = true    # If this container stops, the entire task stops
      
      # PORT MAPPING
      # containerPort: port your app listens on inside container
      # hostPort: omitted for Fargate (AWS assigns dynamically)
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          name          = "frontend-port"
        }
      ]
      
      # RESOURCE LIMITS (optional but recommended)
      # These are hard limits - container is killed if exceeded
      # cpu          = 256    # CPU units for this specific container
      # memory       = 256    # Memory in MB for this specific container
      # memoryReservation = 128  # Soft memory limit (allows bursting)
      
      # LOGGING CONFIGURATION
      # All container stdout/stderr goes to CloudWatch Logs
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.name_prefix}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "frontend"
        }
      }
      
      # ENVIRONMENT VARIABLES
      # Static configuration that doesn't change between deployments
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "80"
        }
      ]
      
      # SECRETS FROM AWS SECRETS MANAGER
      # Dynamic configuration that changes or contains sensitive data
      # secrets = [
      #   {
      #     name      = "DB_PASSWORD"
      #     valueFrom = var.db_secret_arn
      #   }
      # ]
      
      # HEALTH CHECK DISABLED - nginx:alpine doesn't have curl
      # healthCheck = {
      #   command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      #   interval    = 30
      #   timeout     = 5
      #   retries     = 3
      #   startPeriod = 60
      # }
      
      # STARTUP DEPENDENCY (if you had multiple containers)
      # dependsOn = [
      #   {
      #     containerName = "backend"
      #     condition     = "HEALTHY"
      #   }
      # ]
    }
  ])
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-frontend-task"
    Type = "ECS Task Definition"
    Purpose = "Frontend container configuration"
  })
}

# BACKEND TASK DEFINITION
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.container_cpu
  memory                  = var.container_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port  # Your Node.js app port (3000)
          protocol      = "tcp"
          name          = "backend-port"
        }
      ]
      
      # BACKEND-SPECIFIC LOGGING
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.name_prefix}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "backend"
        }
      }
      
      # BACKEND ENVIRONMENT VARIABLES
      # These connect your app to the database
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "guestbook_db"
        },
        {
          name  = "DB_USER"
          value = "app_user"
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        }
      ]
      
      # SECRETS: Database password from Secrets Manager
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ]
      
      # BACKEND HEALTH CHECK DISABLED - httpd:alpine doesn't have curl
      # healthCheck = {
      #   command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
      #   interval    = 30
      #   timeout     = 5
      #   retries     = 3
      #   startPeriod = 90
      # }
    }
  ])
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-task"
    Type = "ECS Task Definition"
    Purpose = "Backend API container configuration"
  })
}

# DEPENDENCY MANAGEMENT: Ensure load balancer is ready before ECS services
resource "null_resource" "lb_ready" {
  # This resource will be created after the HTTP listener ARN is available
  # ECS services depend on this to ensure proper ordering
  triggers = {
    http_listener_arn = var.http_listener_arn
  }
}

# TEACHING POINT: ECS Service
# A service ensures a specified number of tasks are always running
# It handles: deployment, health checks, load balancer registration, auto-scaling

resource "aws_ecs_service" "frontend" {
  name            = "${var.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  
  # DESIRED STATE
  desired_count = var.desired_count  # How many containers should be running
  
  # LAUNCH TYPE vs CAPACITY PROVIDER
  # launch_type = "FARGATE"  # Old way: specify launch type directly
  
  # NEW WAY: Use capacity provider strategy (more flexible)
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 100
    base             = var.desired_count
  }
  
  # OPTIONAL: Use Fargate Spot for cost savings
  # capacity_provider_strategy {
  #   capacity_provider = "FARGATE_SPOT"
  #   weight           = 0    # Set to > 0 to use spot instances
  #   base             = 0
  # }
  
  # PLATFORM VERSION
  # Latest = newest features but potential breaking changes
  # Specific version = stable but may miss security updates
  platform_version = "LATEST"
  
  # NETWORK CONFIGURATION (required for Fargate)
  network_configuration {
    subnets          = var.public_subnet_ids    # Temporarily use public subnets
    security_groups  = [var.ecs_sg_id]          # Security group allows ALB traffic
    assign_public_ip = true                     # Enable public IPs for troubleshooting
  }
  
  # LOAD BALANCER INTEGRATION - Frontend microservice
  # Routes frontend traffic (/, /static/*, etc.) to frontend containers
  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 80
  }
  
  # DEPLOYMENT CONFIGURATION - TEMPORARILY DISABLED FOR COMPATIBILITY
  # Controls how updates are rolled out
  # deployment_configuration {
  #   maximum_percent         = 200  # Can have up to 200% of desired during deployment
  #   minimum_healthy_percent = 100  # Must maintain 100% healthy during deployment
  # }
  
  # DEPLOYMENT CIRCUIT BREAKER - TEMPORARILY DISABLED FOR COMPATIBILITY
  # Automatically rolls back failed deployments
  # deployment_circuit_breaker {
  #   enable   = true
  #   rollback = true  # Auto-rollback on failure
  # }
  
  # DEPLOYMENT CONTROLLER TYPE
  # ECS = standard rolling deployment
  # CODE_DEPLOY = blue/green deployment
  # EXTERNAL = custom deployment tool
  deployment_controller {
    type = "ECS"
  }
  
  # HEALTH CHECK GRACE PERIOD
  # How long to wait after starting before health checks begin
  health_check_grace_period_seconds = var.health_check_grace_period
  
  # SERVICE DISCOVERY (optional)
  # Allows containers to find each other by name
  # service_registries {
  #   registry_arn = aws_service_discovery_service.frontend.arn
  # }
  
  # LIFECYCLE MANAGEMENT
  # Prevent accidental deletion and ignore task definition changes
  lifecycle {
    ignore_changes = [
      task_definition,  # Allow deployments to update task definition
      desired_count     # Allow auto-scaling to change desired count
    ]
  }
  
  # DEPENDENCIES: Both IAM permissions and load balancer must be ready
  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    null_resource.lb_ready
  ]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-frontend-service"
    Type = "ECS Service"
    Purpose = "Frontend container service management"
  })
}

# BACKEND SERVICE
resource "aws_ecs_service" "backend" {
  name            = "${var.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_count
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 100
    base             = var.desired_count
  }
  
  platform_version = "LATEST"
  
  network_configuration {
    subnets          = var.public_subnet_ids    # Temporarily use public subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true                     # Enable public IPs for troubleshooting
  }
  
  # LOAD BALANCER INTEGRATION - Backend microservice  
  # Routes API traffic (/api/*, /health) to backend containers
  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = var.container_port
  }
  
  # deployment_configuration {
  #   maximum_percent         = 200
  #   minimum_healthy_percent = 100
  # }
  
  # deployment_circuit_breaker {
  #   enable   = true
  #   rollback = true
  # }
  
  deployment_controller {
    type = "ECS"
  }
  
  health_check_grace_period_seconds = var.health_check_grace_period
  
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  
  # DEPENDENCIES: Both IAM permissions and load balancer must be ready  
  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    null_resource.lb_ready
  ]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-service"
    Type = "ECS Service"
    Purpose = "Backend API service management"
  })
}

# DATA SOURCES
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}