# Security Module Outputs

output "alb_sg_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "database_sg_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.database.id
}

output "bastion_sg_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion.id
}

output "waf_sg_id" {
  description = "Security group ID for WAF resources"
  value       = aws_security_group.waf.id
}

output "security_group_summary" {
  description = "Summary of all security groups created"
  value = {
    alb = {
      id   = aws_security_group.alb.id
      name = aws_security_group.alb.name
      description = "Allows HTTP/HTTPS from internet, forwards to ECS"
      ingress_ports = ["80", "443"]
    }
    ecs = {
      id   = aws_security_group.ecs.id
      name = aws_security_group.ecs.name
      description = "Allows traffic from ALB, outbound to database and AWS services"
      ingress_ports = ["3000"]
    }
    database = {
      id   = aws_security_group.database.id
      name = aws_security_group.database.name
      description = "Allows PostgreSQL connections from ECS tasks only"
      ingress_ports = ["5432"]
    }
    bastion = {
      id   = aws_security_group.bastion.id
      name = aws_security_group.bastion.name
      description = "SSH access for debugging (remove in production)"
      ingress_ports = ["22"]
    }
  }
}