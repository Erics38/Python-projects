@echo off
echo === STEP-BY-STEP INFRASTRUCTURE CLEANUP ===
echo.
echo Step 1: Delete Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:027660363574:loadbalancer/app/guestbook-demo-alb/6faeaa4985c608e8
echo Load balancer deletion initiated...
echo.

echo Step 2: Wait 2 minutes for load balancer to delete, then continue...
timeout /t 120 /nobreak

echo Step 3: Delete ECS Cluster
aws ecs delete-cluster --cluster guestbook-demo-cluster
echo ECS cluster deletion initiated...
echo.

echo Step 4: Check for RDS instances
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'guestbook')].[DBInstanceIdentifier,DBInstanceStatus]" --output table
echo.

echo Step 5: Delete RDS instances (if any exist)
echo Run manually: aws rds delete-db-instance --db-instance-identifier [IDENTIFIER] --skip-final-snapshot
echo.

echo Step 6: Delete unused security groups (after resources are gone)
echo This will be done in the next script...
echo.

echo === CLEANUP PHASE 1 COMPLETE ===
echo Wait 5-10 minutes, then run cleanup-security-groups.bat