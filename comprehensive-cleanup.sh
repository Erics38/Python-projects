#!/bin/bash
# Comprehensive AWS Resource Cleanup Script
# This script systematically removes all conflicting resources

set -e

REGION="us-east-1"
ENVIRONMENT="demo"
PROJECT="guestbook"

echo "Starting comprehensive AWS resource cleanup for ${PROJECT}-${ENVIRONMENT}..."

# Function to safely delete resource if it exists
safe_delete() {
    local command="$1"
    local resource_name="$2"
    echo "Attempting to delete: $resource_name"
    if eval "$command" 2>/dev/null; then
        echo "✅ Successfully deleted: $resource_name"
    else
        echo "ℹ️  Resource not found or already deleted: $resource_name"
    fi
}

# 1. Delete Secrets Manager Secret
echo "🔐 Cleaning up Secrets Manager..."
safe_delete "aws secretsmanager delete-secret --secret-id '${PROJECT}-${ENVIRONMENT}-db-credentials' --force-delete-without-recovery --region ${REGION}" "Secrets Manager Secret"

# 2. Delete RDS Resources (in dependency order)
echo "🗄️ Cleaning up RDS resources..."
# First, delete any RDS instances that might depend on subnet groups
DB_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT}-${ENVIRONMENT}')].DBInstanceIdentifier" --output text --region ${REGION})
for instance in $DB_INSTANCES; do
    if [ ! -z "$instance" ]; then
        echo "Deleting RDS instance: $instance"
        aws rds delete-db-instance --db-instance-identifier "$instance" --skip-final-snapshot --region ${REGION} || true
        echo "Waiting for RDS instance deletion..."
        aws rds wait db-instance-deleted --db-instance-identifier "$instance" --region ${REGION} || true
    fi
done

# Delete DB Parameter Groups
PARAM_GROUPS=$(aws rds describe-db-parameter-groups --query "DBParameterGroups[?contains(DBParameterGroupName, '${PROJECT}-${ENVIRONMENT}')].DBParameterGroupName" --output text --region ${REGION})
for group in $PARAM_GROUPS; do
    if [ ! -z "$group" ]; then
        safe_delete "aws rds delete-db-parameter-group --db-parameter-group-name '$group' --region ${REGION}" "DB Parameter Group: $group"
    fi
done

# Delete DB Subnet Groups
safe_delete "aws rds delete-db-subnet-group --db-subnet-group-name '${PROJECT}-${ENVIRONMENT}-db-subnet-group' --region ${REGION}" "RDS Subnet Group"

# 3. Delete Load Balancer Resources
echo "⚖️ Cleaning up Load Balancer resources..."
# Get load balancer ARN
ALB_ARN=$(aws elbv2 describe-load-balancers --names "${PROJECT}-${ENVIRONMENT}-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text --region ${REGION} 2>/dev/null || echo "None")
if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "null" ]; then
    echo "Deleting Load Balancer: ${PROJECT}-${ENVIRONMENT}-alb"
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region ${REGION} || true
    echo "Waiting for Load Balancer deletion..."
    aws elbv2 wait load-balancer-deleted --load-balancer-arns "$ALB_ARN" --region ${REGION} || true
fi

# Delete Target Groups
TG_ARN=$(aws elbv2 describe-target-groups --names "${PROJECT}-${ENVIRONMENT}-app-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region ${REGION} 2>/dev/null || echo "None")
if [ "$TG_ARN" != "None" ] && [ "$TG_ARN" != "null" ]; then
    safe_delete "aws elbv2 delete-target-group --target-group-arn '$TG_ARN' --region ${REGION}" "Target Group"
fi

# 4. Delete EIP Resources
echo "🌐 Cleaning up Elastic IP addresses..."
EIP_ALLOCS=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=${PROJECT}-${ENVIRONMENT}*" --query "Addresses[].AllocationId" --output text --region ${REGION})
for alloc_id in $EIP_ALLOCS; do
    if [ ! -z "$alloc_id" ] && [ "$alloc_id" != "None" ]; then
        safe_delete "aws ec2 release-address --allocation-id '$alloc_id' --region ${REGION}" "Elastic IP: $alloc_id"
    fi
done

# 5. Delete CloudWatch Resources
echo "📊 Cleaning up CloudWatch resources..."
safe_delete "aws logs delete-log-group --log-group-name '/aws/ecs/${PROJECT}-${ENVIRONMENT}-cluster-app' --region ${REGION}" "CloudWatch Log Group (ECS)"
safe_delete "aws logs delete-log-group --log-group-name '/aws/waf/${ENVIRONMENT}-${PROJECT}' --region ${REGION}" "CloudWatch Log Group (WAF)"

# 6. Delete WAF Resources
echo "🛡️ Cleaning up WAF resources..."
# Get WAF IP Set ID
IP_SET_ID=$(aws wafv2 list-ip-sets --scope REGIONAL --query "IPSets[?Name=='${ENVIRONMENT}-allowed-ips'].Id" --output text --region ${REGION} 2>/dev/null || echo "")
if [ ! -z "$IP_SET_ID" ] && [ "$IP_SET_ID" != "None" ]; then
    LOCK_TOKEN=$(aws wafv2 get-ip-set --name "${ENVIRONMENT}-allowed-ips" --scope REGIONAL --id "$IP_SET_ID" --query "IPSet.LockToken" --output text --region ${REGION} 2>/dev/null || echo "")
    if [ ! -z "$LOCK_TOKEN" ]; then
        safe_delete "aws wafv2 delete-ip-set --name '${ENVIRONMENT}-allowed-ips' --scope REGIONAL --id '$IP_SET_ID' --lock-token '$LOCK_TOKEN' --region ${REGION}" "WAF IP Set"
    fi
fi

# 7. Delete IAM Resources
echo "👤 Cleaning up IAM resources..."
# Detach policies first, then delete roles
LAMBDA_ROLE="${ENVIRONMENT}-security-headers-lambda-role"
if aws iam get-role --role-name "$LAMBDA_ROLE" --region ${REGION} >/dev/null 2>&1; then
    echo "Detaching policies from Lambda role..."
    aws iam detach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" --region ${REGION} 2>/dev/null || true
    safe_delete "aws iam delete-role --role-name '$LAMBDA_ROLE' --region ${REGION}" "Lambda IAM Role"
fi

# 8. Delete Lambda Functions
echo "λ Cleaning up Lambda functions..."
safe_delete "aws lambda delete-function --function-name '${ENVIRONMENT}-security-headers' --region ${REGION}" "Lambda Function"

# 9. Delete Security Groups (last, after dependencies are gone)
echo "🔒 Cleaning up Security Groups..."
# We'll let Terraform handle security group cleanup since they have complex dependencies

# 10. Delete ACM Certificates that are stuck
echo "🔐 Cleaning up ACM Certificates..."
CERT_ARNS=$(aws acm list-certificates --query "CertificateSummaryList[?contains(DomainName, '${ENVIRONMENT}.example.com')].CertificateArn" --output text --region ${REGION})
for cert_arn in $CERT_ARNS; do
    if [ ! -z "$cert_arn" ] && [ "$cert_arn" != "None" ]; then
        safe_delete "aws acm delete-certificate --certificate-arn '$cert_arn' --region ${REGION}" "ACM Certificate: $cert_arn"
    fi
done

echo "🎉 Cleanup completed! You can now run terraform apply"

# Summary of cleaned resources
echo ""
echo "📋 Cleanup Summary:"
echo "- Secrets Manager secrets"
echo "- RDS instances, parameter groups, and subnet groups"  
echo "- Load balancers and target groups"
echo "- Elastic IP addresses"
echo "- CloudWatch log groups"
echo "- WAF IP sets"
echo "- IAM roles and Lambda functions"
echo "- ACM certificates"
echo ""
echo "⚠️  Note: Some resources may take a few minutes to fully delete."
echo "🔄 Wait 2-3 minutes before running terraform apply"