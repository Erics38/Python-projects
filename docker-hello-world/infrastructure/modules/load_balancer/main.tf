# Load Balancer Module
# Creates Application Load Balancer (ALB) with SSL/TLS termination
# Implements security best practices and production-ready configuration

# TEACHING POINT: Application Load Balancer (ALB)
# ALB operates at Layer 7 (HTTP/HTTPS) and provides:
# - SSL/TLS termination (handles HTTPS certificates)
# - Content-based routing (route by URL path, headers, etc.)
# - Health checks for backend services
# - Integration with AWS services (ECS, Auto Scaling, etc.)
# - WebSocket support
# - Sticky sessions (if needed)

resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false  # Internet-facing (not internal to VPC)
  load_balancer_type = "application"  # ALB vs Network Load Balancer (NLB)
  
  # NETWORK CONFIGURATION
  # ALB must be in public subnets to receive internet traffic
  # ALB will forward traffic to targets in private subnets
  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids
  
  # SECURITY BEST PRACTICES
  enable_deletion_protection = false  # Set to true in production to prevent accidental deletion
  
  # ACCESS LOGGING (optional but recommended for production)
  # Uncomment and configure S3 bucket for access logs
  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs.bucket
  #   prefix  = "alb-access-logs"
  #   enabled = true
  # }
  
  # PERFORMANCE AND AVAILABILITY
  enable_cross_zone_load_balancing = true  # Distribute traffic evenly across AZs
  idle_timeout                    = 60     # Seconds before idle connections are closed
  enable_http2                    = true   # Enable HTTP/2 for better performance
  
  # DROP INVALID HEADERS (security feature)
  drop_invalid_header_fields = true  # Drop headers that don't conform to HTTP standards
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
    Type = "Application Load Balancer"
    Purpose = "Internet-facing load balancer for web application"
    Tier = "Frontend"
  })
}

# TEACHING POINT: Target Groups
# Target groups define how the load balancer routes traffic to backend services
# Each target group can have different health check settings and routing rules

# FRONTEND TARGET GROUP - Serves static content and web UI
resource "aws_lb_target_group" "frontend" {
  name     = "${var.name_prefix}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"      # Frontend root page
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  deregistration_delay = 30
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-frontend-target-group"
    Type = "ALB Target Group"
    Purpose = "Routes traffic to frontend containers"
    Service = "Frontend"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# BACKEND TARGET GROUP - Serves API endpoints and business logic
resource "aws_lb_target_group" "backend" {
  name     = "${var.name_prefix}-backend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"  # Backend health endpoint
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  deregistration_delay = 30
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-target-group"
    Type = "ALB Target Group"
    Purpose = "Routes API traffic to backend containers"
    Service = "Backend"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# TEACHING POINT: SSL/TLS Certificate
# ACM (AWS Certificate Manager) provides free SSL certificates
# This creates a certificate that's automatically validated and renewed

resource "aws_acm_certificate" "main" {
  count = var.domain_name != "" ? 1 : 0
  
  domain_name       = var.domain_name
  validation_method = "DNS"  # DNS validation is preferred over email
  
  # SUBJECT ALTERNATIVE NAMES (SANs)
  # Add additional domains that this certificate should cover
  subject_alternative_names = ["*.${var.domain_name}"]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssl-cert"
    Type = "SSL Certificate"
    Purpose = "HTTPS encryption for web application"
  })
  
  # LIFECYCLE: Create new certificate before destroying old one
  lifecycle {
    create_before_destroy = true
  }
}

# TEACHING POINT: HTTP Listener (Port 80)
# This listener handles HTTP traffic and redirects it to HTTPS
# Security best practice: never serve sensitive content over plain HTTP

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  # CONDITIONAL ACTION: Forward to frontend if no HTTPS, redirect if HTTPS enabled
  default_action {
    type             = var.domain_name != "" ? "redirect" : "forward"
    
    # Forward to frontend target group when HTTPS disabled (demo mode)
    dynamic "forward" {
      for_each = var.domain_name == "" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.frontend.arn
        }
      }
    }
    
    # Redirect to HTTPS when HTTPS enabled (production mode)  
    dynamic "redirect" {
      for_each = var.domain_name != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-http-listener"
    Type = "ALB Listener"
    Purpose = "HTTP traffic routing"
  })
}

# API ROUTING RULE FOR HTTP - Route /api/* to backend
resource "aws_lb_listener_rule" "api_http" {
  count = var.domain_name == "" ? 1 : 0  # Only create when HTTPS is disabled
  
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  
  condition {
    path_pattern {
      values = ["/api/*", "/health"]
    }
  }
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-http-rule"
    Type = "ALB Listener Rule"
    Purpose = "Route API traffic to backend service"
  })
}

# TEACHING POINT: HTTPS Listener (Port 443)
# This is where the actual application traffic is handled
# SSL termination happens here - traffic to targets can be HTTP

resource "aws_lb_listener" "https" {
  count = var.domain_name != "" ? 1 : 0
  
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  
  # SSL CONFIGURATION
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Strong TLS policy
  certificate_arn = aws_acm_certificate.main[0].arn
  
  # DEFAULT ACTION: Forward to frontend target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-https-listener"
    Type = "ALB Listener"
    Purpose = "HTTPS traffic handling with SSL termination"
  })
}

# TEACHING POINT: Listener Rules (Optional)
# These allow advanced routing based on conditions
# Examples: route /api/* to backend service, /static/* to S3, etc.

# API ROUTING RULE FOR HTTPS - Route /api/* to backend
resource "aws_lb_listener_rule" "api_https" {
  count = var.domain_name != "" ? 1 : 0
  
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100
  
  condition {
    path_pattern {
      values = ["/api/*", "/health"]
    }
  }
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-https-rule"
    Type = "ALB Listener Rule"
    Purpose = "Route API traffic to backend service (HTTPS)"
  })
}

# OPTIONAL: S3 Bucket for Access Logs
# Uncomment if you want to store ALB access logs for analysis

# resource "aws_s3_bucket" "alb_logs" {
#   bucket        = "${var.name_prefix}-alb-access-logs-${random_id.bucket_suffix.hex}"
#   force_destroy = true  # Allow destruction even if bucket contains objects
#   
#   tags = merge(var.tags, {
#     Name = "${var.name_prefix}-alb-logs"
#     Type = "S3 Bucket"
#     Purpose = "ALB access logs storage"
#   })
# }

# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }

# resource "aws_s3_bucket_policy" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id
#   
#   # Policy that allows ALB to write logs to this bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.alb_logs.arn}/alb-access-logs/*"
#       }
#     ]
#   })
# }

# data "aws_elb_service_account" "main" {}

# TEACHING POINT: Route53 DNS Record (Optional)
# If you have a custom domain, this creates DNS records pointing to the ALB
# Uncomment and configure if you have a Route53 hosted zone

# data "aws_route53_zone" "main" {
#   count = var.domain_name != "" ? 1 : 0
#   name  = var.domain_name
# }

# resource "aws_route53_record" "main" {
#   count   = var.domain_name != "" ? 1 : 0
#   zone_id = data.aws_route53_zone.main[0].zone_id
#   name    = var.domain_name
#   type    = "A"
#   
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }

# CLOUDWATCH ALARMS for ALB Monitoring
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.name_prefix}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"  # 5 minutes
  statistic           = "Average"
  threshold           = "1.0"  # 1 second response time threshold
  alarm_description   = "This metric monitors ALB target response time"
  alarm_actions       = []     # TODO: Add SNS topic for notifications
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-response-time-alarm"
    Type = "CloudWatch Alarm"
    Purpose = "ALB performance monitoring"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_host_count" {
  alarm_name          = "${var.name_prefix}-alb-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"   # 1 minute
  statistic           = "Average"
  threshold           = "1"    # Alert if less than 1 healthy target
  alarm_description   = "This metric monitors number of healthy targets"
  alarm_actions       = []     # TODO: Add SNS topic for notifications
  
  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-healthy-hosts-alarm"
    Type = "CloudWatch Alarm"
    Purpose = "ALB target health monitoring"
  })
}

