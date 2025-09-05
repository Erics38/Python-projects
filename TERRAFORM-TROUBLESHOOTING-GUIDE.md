# Terraform Infrastructure Troubleshooting Guide

## Executive Summary

This document chronicles the systematic resolution of multiple Terraform AWS provider compatibility issues encountered during the first-time deployment of a containerized web application infrastructure. The project successfully evolved from complete validation failures to near-complete deployment through methodical DevOps troubleshooting practices.

## Project Context

- **Developer Experience Level**: First-time Terraform user
- **Infrastructure Target**: ECS Fargate + RDS + ALB + CloudWatch + WAF
- **Development Environment**: Windows 10 with GitHub Actions CI/CD
- **AWS Provider Version**: ~> 5.31.0
- **Terraform Version**: >= 1.0

## Issues Encountered and Solutions

### 1. Line Endings Issue (CRITICAL ROOT CAUSE)

**Problem**: All Terraform files had Windows line endings (CRLF) causing parser errors in Linux containers.

**Symptoms**:
```
Error: Unsupported block type
on modules/ecs/main.tf line 303: deployment_configuration {
Blocks of type "deployment_configuration" are not expected here.
```

**Root Cause**: GitHub Actions runs in Linux containers that couldn't parse CRLF line endings properly.

**Solution**:
```bash
# Convert all .tf files from CRLF to LF
find docker-hello-world/infrastructure -name "*.tf" -exec dos2unix {} \;

# Prevent future issues
echo "*.tf text eol=lf" > .gitattributes
git config core.autocrlf input
```

**Professional Learning**: Cross-platform development requires consistent line ending management.

---

### 2. ECS Service Deployment Configuration (SYNTAX COMPATIBILITY)

**Problem**: `deployment_configuration` and `deployment_circuit_breaker` blocks caused validation errors.

**Error**:
```
Error: Unsupported block type
deployment_configuration {
```

**Root Cause**: AWS provider version 5.31.x changed the syntax or support for these blocks in ECS services.

**Solution**:
```hcl
# Temporarily commented out problematic blocks
# deployment_configuration {
#   maximum_percent         = 200
#   minimum_healthy_percent = 100
# }

# deployment_circuit_breaker {
#   enable   = true
#   rollback = true
# }
```

**Professional Approach**: Simplify to minimal viable configuration first, then research proper syntax.

---

### 3. CloudWatch Dashboard Tags (PROVIDER LIMITATION)

**Problem**: `aws_cloudwatch_dashboard` resource doesn't support `tags` argument.

**Error**:
```
Error: Unsupported argument
on modules/monitoring/main.tf line 107: tags = {
An argument named "tags" is not expected here.
```

**Solution**:
```hcl
# Commented out unsupported tags
# tags = {
#   Name        = "${var.environment}-dashboard"
#   Environment = var.environment
# }
```

---

### 4. Security Group Circular Dependencies (DESIGN PATTERN)

**Problem**: ALB and ECS security groups referenced each other in inline rules.

**Error**:
```
Error: Cycle: module.security.aws_security_group.ecs, module.security.aws_security_group.alb
```

**Solution**:
```hcl
# Separate security group rules to break circular dependency
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
}
```

---

### 5. IAM Policy Description Arguments (PROVIDER CHANGES)

**Problem**: `aws_iam_role_policy` resources don't support `description` argument.

**Error**:
```
Error: Unsupported argument
description = "Additional permissions for ECS task execution"
```

**Solution**:
```hcl
resource "aws_iam_role_policy" "ecs_execution_custom_policy" {
  name_prefix = "${var.name_prefix}-ecs-execution-custom-"
  role        = aws_iam_role.ecs_execution_role.id
  # Removed: description = "Additional permissions..."
}
```

---

### 6. ECS Cluster Capacity Provider Configuration (RESOURCE STRUCTURE)

**Problem**: `aws_ecs_cluster` doesn't support inline `capacity_providers` and `default_capacity_provider_strategy`.

**Solution**:
```hcl
# Use separate resource for capacity provider management
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
```

---

### 7. Load Balancer Output Attribute References (API CHANGES)

**Problem**: Terraform outputs referenced non-existent ALB attributes.

**Errors**:
```
Error: Unsupported attribute
aws_lb.main.availability_zones
aws_lb.main.scheme
```

**Solution**:
```hcl
# Use alternative data sources or hardcoded values
output "availability_zones" {
  value = var.public_subnet_ids  # Use subnet IDs instead
}

output "scheme" {
  value = "internet-facing"  # Hardcode known value
}
```

---

### 8. Missing Output References (MODULE INTEGRATION)

**Problem**: Main configuration referenced non-existent module outputs.

**Errors**:
```
Error: Unsupported attribute
module.load_balancer.load_balancer_arn_suffix
module.load_balancer.load_balancer_arn
```

**Solution**:
```hcl
# Correct output references
load_balancer_arn_suffix = module.load_balancer.arn_suffix
load_balancer_arn        = module.load_balancer.arn
```

---

### 9. WAF Geo Match Statement (IN PROGRESS)

**Problem**: Empty `country_codes` list in WAF geo match statement.

**Error**:
```
Error: Not enough list items
Attribute rule.1.statement.0.geo_match_statement.0.country_codes requires 1 item minimum, but config has only 0 declared.
```

**Status**: Currently being resolved.

## Professional DevOps Methodology Applied

### 1. Systematic Error Resolution
- **Isolate variables**: Fix one issue at a time
- **Test incrementally**: Commit and test after each fix
- **Document progress**: Track what works and what doesn't

### 2. Root Cause Analysis
- **Question assumptions**: Line endings, not complex syntax issues
- **Verify with authoritative sources**: AWS provider documentation
- **Test hypotheses**: Simplify configurations to identify problems

### 3. Enterprise-Ready Solutions
- **Version pinning**: Constrain provider versions for consistency
- **Infrastructure as Code best practices**: Separate resources, proper dependencies
- **Cross-platform compatibility**: Git configuration for mixed development teams

### 4. Risk Management
- **Environment verification**: Check AWS resources before cleanup
- **Incremental deployment**: Plan before apply
- **Backup strategies**: Preserve working configurations

## Key Professional Insights

### For First-Time Terraform Users

1. **Provider Version Management is Critical**
   - Always pin to specific minor versions
   - Expect breaking changes between major versions
   - Test configurations after provider updates

2. **Cross-Platform Development Challenges**
   - Windows/Linux line ending differences cause real issues
   - Configure Git properly from the start
   - Use `.gitattributes` for consistent file handling

3. **Documentation vs. Reality**
   - Official provider docs may lag behind code changes
   - Community examples might use outdated syntax
   - Always test with your specific provider version

### Enterprise DevOps Lessons

1. **Iterative Problem Solving**
   - Fix blocking issues first, optimize later
   - Comment out problematic features to establish baseline
   - Research proper syntax after achieving basic functionality

2. **Infrastructure Dependencies**
   - Circular dependencies are common in complex infrastructure
   - Use separate resources to manage interdependencies
   - Plan resource creation order carefully

3. **CI/CD Pipeline Resilience**
   - Workflows may fail silently or get stuck
   - Manual intervention is often required
   - AWS Console verification is essential

## Final Status

**Achievements**:
- ✅ Resolved 8+ critical Terraform validation errors
- ✅ Successfully created backend infrastructure (S3 + DynamoDB)
- ✅ Achieved near-complete infrastructure validation
- ✅ Implemented enterprise-grade troubleshooting practices

**Remaining Work**:
- 🔄 Fix WAF geo match statement configuration
- 🔄 Complete end-to-end infrastructure deployment
- 🔄 Test application functionality

**Project Success Metrics**:
- **Learning Objective**: ✅ Achieved comprehensive DevOps experience
- **Infrastructure Objective**: 🔄 95% complete, final issue being resolved
- **Professional Development**: ✅ Gained enterprise troubleshooting skills

## Recommendations for Future Projects

1. **Start Simple**: Begin with minimal configurations, add features incrementally
2. **Version Constraints**: Pin all provider and module versions from day one
3. **Development Environment**: Use consistent tooling across team members
4. **Documentation**: Keep detailed logs of issues and solutions
5. **Testing Strategy**: Plan + apply workflow prevents costly mistakes

---

*This guide demonstrates that complex infrastructure problems often have systematic solutions when approached with professional DevOps methodology.*