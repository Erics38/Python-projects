@echo off
echo === INFRASTRUCTURE CLEANUP SCRIPT ===
echo WARNING: This will destroy AWS resources and may incur costs!
echo.
pause

echo === Step 1: Destroy with Terraform (Safest Method) ===
echo Navigate to your infrastructure directory and run:
echo   terraform destroy
echo.
echo If you have multiple environments, destroy each one:
echo   terraform destroy -var-file="environments/demo.tfvars"
echo   terraform destroy -var-file="environments/dev.tfvars"
echo   terraform destroy -var-file="environments/prod.tfvars"
echo.
pause

echo === Step 2: Manual Cleanup (if Terraform fails) ===
echo.
echo Checking for ECS services that need to be stopped first...
aws ecs list-services --cluster guestbook-demo --query "serviceArns[*]" --output table

echo.
echo If services exist, scale them down to 0:
echo aws ecs update-service --cluster guestbook-demo --service [SERVICE-NAME] --desired-count 0
echo.
pause

echo === Step 3: List resources to delete manually ===
echo.
echo Load Balancers:
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'guestbook')].[LoadBalancerName,LoadBalancerArn]" --output table

echo.
echo RDS Instances:
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'guestbook')].[DBInstanceIdentifier,DBInstanceStatus]" --output table

echo.
echo ECS Clusters:
aws ecs list-clusters --query "clusterArns[*]" --output table

echo.
echo === MANUAL DELETION COMMANDS (USE WITH CAUTION) ===
echo.
echo Delete Load Balancers:
echo aws elbv2 delete-load-balancer --load-balancer-arn [ARN]
echo.
echo Delete RDS Instances:
echo aws rds delete-db-instance --db-instance-identifier [IDENTIFIER] --skip-final-snapshot
echo.
echo Delete ECS Clusters:
echo aws ecs delete-cluster --cluster [CLUSTER-NAME]
echo.
echo Delete VPCs (after all resources are gone):
echo aws ec2 delete-vpc --vpc-id [VPC-ID]