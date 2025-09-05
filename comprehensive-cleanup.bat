@echo off
REM Comprehensive AWS Resource Cleanup Script - Windows Version
REM This script systematically removes all conflicting resources

setlocal enabledelayedexpansion

set REGION=us-east-1
set ENVIRONMENT=demo
set PROJECT=guestbook

echo Starting comprehensive AWS resource cleanup for %PROJECT%-%ENVIRONMENT%...

REM 1. Delete Secrets Manager Secret
echo 🔐 Cleaning up Secrets Manager...
aws secretsmanager delete-secret --secret-id "%PROJECT%-%ENVIRONMENT%-db-credentials" --force-delete-without-recovery --region %REGION% 2>nul && echo ✅ Deleted Secrets Manager Secret || echo ℹ️ Secrets Manager Secret not found

REM 2. Delete RDS Subnet Group
echo 🗄️ Cleaning up RDS resources...
aws rds delete-db-subnet-group --db-subnet-group-name "%PROJECT%-%ENVIRONMENT%-db-subnet-group" --region %REGION% 2>nul && echo ✅ Deleted RDS Subnet Group || echo ℹ️ RDS Subnet Group not found

REM 3. Delete Load Balancer
echo ⚖️ Cleaning up Load Balancer...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names "%PROJECT%-%ENVIRONMENT%-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text --region %REGION% 2^>nul') do set ALB_ARN=%%i
if defined ALB_ARN if not "%ALB_ARN%"=="None" (
    aws elbv2 delete-load-balancer --load-balancer-arn "%ALB_ARN%" --region %REGION% 2>nul && echo ✅ Deleted Load Balancer
)

REM 4. Delete Target Group
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names "%PROJECT%-%ENVIRONMENT%-app-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region %REGION% 2^>nul') do set TG_ARN=%%i
if defined TG_ARN if not "%TG_ARN%"=="None" (
    aws elbv2 delete-target-group --target-group-arn "%TG_ARN%" --region %REGION% 2>nul && echo ✅ Deleted Target Group
)

REM 5. Delete Elastic IP addresses
echo 🌐 Cleaning up Elastic IP addresses...
aws ec2 release-address --allocation-id eipalloc-0123456789abcdef0 --region %REGION% 2>nul || echo ℹ️ EIPs handled

REM 6. Delete CloudWatch Log Groups
echo 📊 Cleaning up CloudWatch resources...
aws logs delete-log-group --log-group-name "/aws/ecs/%PROJECT%-%ENVIRONMENT%-cluster-app" --region %REGION% 2>nul && echo ✅ Deleted ECS Log Group || echo ℹ️ ECS Log Group not found
aws logs delete-log-group --log-group-name "/aws/waf/%ENVIRONMENT%-%PROJECT%" --region %REGION% 2>nul && echo ✅ Deleted WAF Log Group || echo ℹ️ WAF Log Group not found

REM 7. Delete IAM Role
echo 👤 Cleaning up IAM resources...
aws iam detach-role-policy --role-name "%ENVIRONMENT%-security-headers-lambda-role" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" --region %REGION% 2>nul
aws iam delete-role --role-name "%ENVIRONMENT%-security-headers-lambda-role" --region %REGION% 2>nul && echo ✅ Deleted Lambda Role || echo ℹ️ Lambda Role not found

REM 8. Delete Lambda Function
echo λ Cleaning up Lambda functions...
aws lambda delete-function --function-name "%ENVIRONMENT%-security-headers" --region %REGION% 2>nul && echo ✅ Deleted Lambda Function || echo ℹ️ Lambda Function not found

echo.
echo 🎉 Cleanup completed! 
echo.
echo 📋 Resources cleaned:
echo - Secrets Manager secrets
echo - RDS subnet groups
echo - Load balancers and target groups
echo - CloudWatch log groups  
echo - IAM roles and Lambda functions
echo.
echo ⚠️ Note: Some resources may take a few minutes to fully delete.
echo 🔄 Wait 2-3 minutes before running terraform apply

pause