# Load Balancer Module Outputs
# Provides essential information about the ALB and related resources
# Used by other modules and for external access

# PRIMARY ACCESS INFORMATION
output "dns_name" {
  description = "DNS name of the load balancer (primary application URL)"
  value       = aws_lb.main.dns_name
  
  # TEACHING POINT: ALB DNS names look like:
  # myapp-alb-123456789.us-east-1.elb.amazonaws.com
  # This is your application URL when not using custom domains
}

output "hosted_zone_id" {
  description = "Hosted zone ID of the load balancer (for Route53 alias records)"
  value       = aws_lb.main.zone_id
  
  # Used when creating Route53 alias records for custom domains
  # Each AWS region has a specific hosted zone ID for ALBs
}

output "arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
  
  # Amazon Resource Name - unique identifier for this ALB
  # Used for IAM policies, CloudWatch alarms, and other AWS service integrations
}

output "arn_suffix" {
  description = "ARN suffix for use with CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
  
  # Used in CloudWatch metric dimensions
  # Format: app/load-balancer-name/1234567890123456
}

# FRONTEND TARGET GROUP INFORMATION
output "frontend_target_group_arn" {
  description = "ARN of the frontend target group (for frontend ECS service)"
  value       = aws_lb_target_group.frontend.arn
}

output "frontend_target_group_name" {
  description = "Name of the frontend target group"
  value       = aws_lb_target_group.frontend.name
}

# BACKEND TARGET GROUP INFORMATION  
output "backend_target_group_arn" {
  description = "ARN of the backend target group (for backend ECS service)"
  value       = aws_lb_target_group.backend.arn
}

output "backend_target_group_name" {
  description = "Name of the backend target group"
  value       = aws_lb_target_group.backend.name
}

# LEGACY OUTPUT - Points to frontend for backward compatibility
output "target_group_arn" {
  description = "ARN of the primary target group (legacy - use specific target groups)"
  value       = aws_lb_target_group.frontend.arn
}

output "target_group_name" {
  description = "Name of the primary target group (legacy)"
  value       = aws_lb_target_group.frontend.name
}

output "target_group_arn_suffix" {
  description = "ARN suffix of primary target group for CloudWatch metrics (legacy)"
  value       = aws_lb_target_group.frontend.arn_suffix
}

# SSL CERTIFICATE INFORMATION
output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].arn : null
  
  # Can be reused for other AWS services (CloudFront, API Gateway, etc.)
}

output "certificate_domain_name" {
  description = "Domain name of the SSL certificate"
  value       = length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].domain_name : null
  
  # The primary domain name this certificate covers
}

output "certificate_validation_options" {
  description = "Certificate validation DNS records (for manual DNS validation)"
  value       = length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].domain_validation_options : []
  sensitive   = true
  
  # If using DNS validation, these records must be added to your DNS
  # Usually handled automatically with Route53, but needed for external DNS
}

# LISTENER INFORMATION
output "http_listener_arn" {
  description = "ARN of the HTTP listener (port 80)"
  value       = aws_lb_listener.http.arn
  
  # Used for creating additional listener rules
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (port 443)"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
  
  # Primary listener for application traffic
  # Used for creating additional routing rules
}

# SECURITY INFORMATION
output "security_group_id" {
  description = "Security group ID attached to the load balancer"
  value       = var.alb_sg_id
  
  # Reference to the security group controlling ALB traffic
}

output "ssl_policy" {
  description = "SSL policy used by HTTPS listener"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].ssl_policy : null
  
  # Current SSL/TLS policy - important for security compliance
}

# NETWORK CONFIGURATION
output "vpc_id" {
  description = "VPC ID where the load balancer is deployed"
  value       = var.vpc_id
  
  # Network context for the load balancer
}

output "subnet_ids" {
  description = "List of subnet IDs where the load balancer is deployed"
  value       = var.public_subnet_ids
  
  # Shows which public subnets the ALB spans
}

output "availability_zones" {
  description = "List of availability zones where the load balancer is deployed"
  value       = var.public_subnet_ids
  
  # Shows AZ distribution for high availability verification
  # Note: Using subnet IDs as ALB availability zones aren't directly accessible
}

# OPERATIONAL INFORMATION
output "load_balancer_type" {
  description = "Type of load balancer (application, network, or gateway)"
  value       = aws_lb.main.load_balancer_type
  
  # Confirms this is an Application Load Balancer
}

output "scheme" {
  description = "Load balancer scheme (internet-facing or internal)"
  value       = "internet-facing"
  
  # Should be "internet-facing" for public web applications
  # Note: Using hardcoded value as scheme isn't exposed by aws_lb resource
}

output "ip_address_type" {
  description = "IP address type (ipv4, dualstack)"
  value       = aws_lb.main.ip_address_type
  
  # Shows whether ALB supports IPv6 (dualstack) or just IPv4
}

# HEALTH CHECK CONFIGURATION
output "health_check_configuration" {
  description = "Target group health check configuration"
  value = {
    enabled             = aws_lb_target_group.app.health_check[0].enabled
    healthy_threshold   = aws_lb_target_group.app.health_check[0].healthy_threshold
    unhealthy_threshold = aws_lb_target_group.app.health_check[0].unhealthy_threshold
    timeout             = aws_lb_target_group.app.health_check[0].timeout
    interval            = aws_lb_target_group.app.health_check[0].interval
    path                = aws_lb_target_group.app.health_check[0].path
    matcher             = aws_lb_target_group.app.health_check[0].matcher
    port                = aws_lb_target_group.app.health_check[0].port
    protocol            = aws_lb_target_group.app.health_check[0].protocol
  }
  
  # Complete health check configuration for documentation and debugging
}

# MONITORING INFORMATION  
output "cloudwatch_alarms" {
  description = "CloudWatch alarms created for load balancer monitoring"
  value = {
    response_time_alarm = aws_cloudwatch_metric_alarm.alb_target_response_time.arn
    healthy_hosts_alarm = aws_cloudwatch_metric_alarm.alb_healthy_host_count.arn
  }
  
  # ARNs of monitoring alarms for integration with notification systems
}

# CONNECTION INFORMATION FOR APPLICATIONS
output "connection_info" {
  description = "Connection information for applications and users"
  value = {
    # Primary application URLs
    http_url  = "http://${aws_lb.main.dns_name}"
    https_url = "https://${aws_lb.main.dns_name}"
    
    # Custom domain URLs (if configured)
    custom_http_url  = var.domain_name != "" ? "http://${var.domain_name}" : null
    custom_https_url = var.domain_name != "" ? "https://${var.domain_name}" : null
    
    # Load balancer details
    dns_name    = aws_lb.main.dns_name
    domain_name = var.domain_name != "" ? var.domain_name : aws_lb.main.dns_name
    
    # Port information
    http_port  = 80
    https_port = 443
    target_port = 3000
  }
  
  # Comprehensive connection details for documentation and automation
}

# COST TRACKING INFORMATION
output "cost_components" {
  description = "Components that contribute to ALB costs for tracking"
  value = {
    load_balancer_hours = "~$0.025/hour (~$18/month)"
    lcu_usage          = "Variable based on traffic (Load Balancer Capacity Units)"
    data_processing    = "~$0.008 per GB processed"
    certificate_cost   = "Free (AWS Certificate Manager)"
    health_checks      = "No additional cost"
    
    notes = [
      "ALB pricing is based on hours running + LCU consumption",
      "LCUs measure connections, requests, bandwidth, and rule evaluations", 
      "First 750 hours/month are free tier eligible for new AWS accounts",
      "Monitor CloudWatch metrics to optimize LCU usage"
    ]
  }
}