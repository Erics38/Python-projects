# 🔐 IAM Permissions for Enterprise Infrastructure Deployment

## Overview

This document outlines the **comprehensive IAM permissions** required for deploying and managing the enterprise-grade containerized application infrastructure via **GitHub Actions** and **Terraform**.

## 🎯 Quick Setup for GitHub Actions

### **Required GitHub Secrets**
Add these to your repository: `Settings` → `Secrets and variables` → `Actions`

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

### **Recommended: Create Dedicated IAM User**
```bash
# Create IAM user for GitHub Actions
aws iam create-user --user-name guestbook-github-actions

# Attach policies (see below)
aws iam attach-user-policy --user-name guestbook-github-actions --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access keys
aws iam create-access-key --user-name guestbook-github-actions
```

## 🏗️ Terraform Infrastructure Permissions

### **Option 1: PowerUser Access (Recommended for Demo)**
For rapid deployment and demonstration purposes:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "organizations:*",
        "account:*",
        "aws-portal:*",
        "billing:*",
        "budgets:*",
        "ce:*",
        "cur:*",
        "support:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Benefits:**
- ✅ Quick setup and deployment
- ✅ Works for all infrastructure components
- ✅ No permission troubleshooting needed
- ⚠️ More permissions than strictly necessary (acceptable for demo/learning)

### **Option 2: Least Privilege Access (Production)**
For production environments, use specific permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCAndNetworking",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecurityGroups",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSPermissions",
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeleteCluster",
        "ecs:DescribeClusters",
        "ecs:CreateService",
        "ecs:DeleteService",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:DescribeTasks",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LoadBalancerPermissions",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeTargetHealth"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSPermissions",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:DescribeDBSubnetGroups",
        "rds:CreateDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBSnapshots"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:ListPolicies",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerPermissions",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecret"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutDashboard",
        "cloudwatch:DeleteDashboards",
        "cloudwatch:GetDashboard",
        "cloudwatch:ListDashboards"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SNSPermissions",
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:GetTopicAttributes",
        "sns:SetTopicAttributes",
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:ListTopics",
        "sns:ListSubscriptionsByTopic"
      ],
      "Resource": "*"
    },
    {
      "Sid": "WAFPermissions",
      "Effect": "Allow",
      "Action": [
        "wafv2:CreateWebACL",
        "wafv2:DeleteWebACL",
        "wafv2:GetWebACL",
        "wafv2:ListWebACLs",
        "wafv2:UpdateWebACL",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL",
        "wafv2:CreateIPSet",
        "wafv2:DeleteIPSet",
        "wafv2:GetIPSet",
        "wafv2:ListIPSets",
        "wafv2:PutLoggingConfiguration",
        "wafv2:DeleteLoggingConfiguration",
        "wafv2:GetLoggingConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ACMPermissions",
      "Effect": "Allow",
      "Action": [
        "acm:RequestCertificate",
        "acm:DeleteCertificate",
        "acm:DescribeCertificate",
        "acm:ListCertificates"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaPermissions",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:ListFunctions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPermissions",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:DeleteRepository",
        "ecr:DescribeRepositories",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchDeleteImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🏢 Backend State Management Permissions

For the professional Terraform backend (S3 + DynamoDB):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformBackend",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": [
        "arn:aws:s3:::guestbook-terraform-state-*",
        "arn:aws:s3:::guestbook-terraform-state-*/*",
        "arn:aws:dynamodb:*:*:table/guestbook-terraform-locks"
      ]
    }
  ]
}
```

## 🔄 Application Runtime Permissions

### **ECS Task Permissions** (Automatically created by Terraform)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:guestbook-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/ecs/guestbook-*"
      ]
    }
  ]
}
```

## 📋 Deployment Checklist

### **Before Running GitHub Actions:**

1. **✅ AWS Account Setup**
   ```bash
   # Verify AWS CLI access
   aws sts get-caller-identity
   ```

2. **✅ Create IAM User**
   ```bash
   # Create user for GitHub Actions
   aws iam create-user --user-name guestbook-github-actions
   
   # Attach PowerUser policy (recommended for demo)
   aws iam attach-user-policy \
     --user-name guestbook-github-actions \
     --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   
   # Create access keys
   aws iam create-access-key --user-name guestbook-github-actions
   ```

3. **✅ Configure GitHub Secrets**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add `AWS_ACCESS_KEY_ID` (from step 2)
   - Add `AWS_SECRET_ACCESS_KEY` (from step 2)

4. **✅ Optional: Email Alerts**
   - Update environment `.tfvars` files with your email
   - Confirm SNS subscription after first deployment

### **GitHub Actions Workflows Available:**

1. **🏗️ Setup Backend** - Initialize Terraform remote state
2. **🚀 Start Demo** - Deploy complete infrastructure
3. **CI/CD Pipeline** - Full enterprise deployment with testing
4. **🛑 Stop Demo** - Cost-effective shutdown
5. **🗑️ Destroy Everything** - Complete cleanup

## 🔧 Common Issues & Solutions

### **Permission Errors**

**Error:** `AccessDenied: User is not authorized to perform X`  
**Solution:** Ensure IAM user has PowerUser access or specific permissions above

**Error:** `InvalidUserID.NotFound`  
**Solution:** Wait 10-60 seconds for IAM user creation to propagate

**Error:** `The security token included in the request is expired`  
**Solution:** Regenerate AWS access keys and update GitHub secrets

### **Network/Resource Errors**

**Error:** `InvalidVpcId.NotFound`  
**Solution:** Ensure region is consistent (us-east-1 by default)

**Error:** `ResourceNotFoundException`  
**Solution:** Check that resource names don't conflict with existing resources

### **Terraform State Errors**

**Error:** `Backend configuration changed`  
**Solution:** Run backend setup workflow first, then main deployment

## 💰 Cost Estimates with Permissions

| Permission Level | Monthly Cost | Use Case |
|------------------|--------------|----------|
| **PowerUser** | Same as infrastructure | Demo, learning, rapid prototyping |
| **Least Privilege** | Same as infrastructure | Production, compliance, security-first |

- **Demo Environment:** ~$50-60/month
- **Production Environment:** ~$200-400/month  
- **IAM Costs:** $0 (IAM users and policies are free)

## 🎯 Quick Start Commands

```bash
# 1. Verify AWS access
aws sts get-caller-identity

# 2. Test specific permissions
aws ec2 describe-vpcs --region us-east-1
aws ecs list-clusters --region us-east-1

# 3. Deploy via GitHub Actions
# Go to Actions tab → "🚀 Start Demo" → Run workflow

# 4. Monitor deployment
# Watch GitHub Actions logs and AWS console
```

## 🔐 Security Best Practices

### **Development Environment**
- ✅ Use PowerUser access for speed
- ✅ Rotate access keys monthly
- ✅ Monitor AWS CloudTrail logs

### **Production Environment**  
- ✅ Use least privilege permissions
- ✅ Enable MFA for IAM users
- ✅ Use IAM roles instead of access keys when possible
- ✅ Regular access reviews and audits
- ✅ Implement AWS Config for compliance

### **GitHub Actions Security**
- ✅ Store credentials as encrypted secrets only
- ✅ Never log AWS credentials in workflows
- ✅ Use environment-specific secrets for prod
- ✅ Monitor GitHub Actions usage and access

---

**Ready to deploy! The infrastructure is designed to work with PowerUser access out of the box, with options to lock down permissions for production use.** 🚀