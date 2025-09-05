@echo off
echo ========================================
echo    SAFER NUCLEAR OPTION
echo ========================================
echo This will delete only guestbook-related resources
echo.
pause

echo === Deleting ECS resources ===
aws ecs update-service --cluster guestbook-demo-cluster --service guestbook-demo-frontend --desired-count 0 2>nul
aws ecs update-service --cluster guestbook-demo-cluster --service guestbook-demo-backend --desired-count 0 2>nul
timeout /t 30 /nobreak
aws ecs delete-service --cluster guestbook-demo-cluster --service guestbook-demo-frontend --force 2>nul
aws ecs delete-service --cluster guestbook-demo-cluster --service guestbook-demo-backend --force 2>nul
aws ecs delete-cluster --cluster guestbook-demo-cluster 2>nul

echo === Deleting Load Balancer ===
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:027660363574:loadbalancer/app/guestbook-demo-alb/6faeaa4985c608e8 2>nul

echo === Deleting RDS instances ===
for /f "tokens=*" %%i in ('aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'guestbook')].DBInstanceIdentifier" --output text') do (
    aws rds delete-db-instance --db-instance-identifier %%i --skip-final-snapshot --delete-automated-backups 2>nul
)

echo === Waiting 3 minutes for resources to delete ===
timeout /t 180 /nobreak

echo === Force deleting security groups ===
aws ec2 delete-security-group --group-id sg-028792c8c94ef606f 2>nul
aws ec2 delete-security-group --group-id sg-0fc2f3815d1cb5938 2>nul
aws ec2 delete-security-group --group-id sg-041fa31fa691f7a67 2>nul
aws ec2 delete-security-group --group-id sg-0dea019db1cf5e281 2>nul
aws ec2 delete-security-group --group-id sg-07f8e4846fbd1cb09 2>nul
aws ec2 delete-security-group --group-id sg-084d14595285bef46 2>nul
aws ec2 delete-security-group --group-id sg-0acc436ef1bdfda04 2>nul
aws ec2 delete-security-group --group-id sg-0f0982d0c7daa9506 2>nul
aws ec2 delete-security-group --group-id sg-02500744655eace0e 2>nul
aws ec2 delete-security-group --group-id sg-04c6e1b416ffc1e97 2>nul
aws ec2 delete-security-group --group-id sg-049381107305efd58 2>nul
aws ec2 delete-security-group --group-id sg-0b71d060d822f594c 2>nul
aws ec2 delete-security-group --group-id sg-0ff2f242e6a1769f9 2>nul
aws ec2 delete-security-group --group-id sg-022d4c9576df7b3b4 2>nul
aws ec2 delete-security-group --group-id sg-0f8021a3d13e71048 2>nul
aws ec2 delete-security-group --group-id sg-0171c2bdc9184cdf7 2>nul
aws ec2 delete-security-group --group-id sg-0124be826cd2392be 2>nul
aws ec2 delete-security-group --group-id sg-095c91a6e2928b262 2>nul
aws ec2 delete-security-group --group-id sg-0c43d4472d891df49 2>nul
aws ec2 delete-security-group --group-id sg-07b1c1ef7fca5b64b 2>nul
aws ec2 delete-security-group --group-id sg-06de86f9beafbe024 2>nul
aws ec2 delete-security-group --group-id sg-0bc30cf3a6d9414f8 2>nul
aws ec2 delete-security-group --group-id sg-0e0e1a95e338b1bcb 2>nul
aws ec2 delete-security-group --group-id sg-016ba904be8edc640 2>nul

echo === Cleaning up VPC components ===
for %%v in (vpc-0899032133b559e32 vpc-095586e614ea1a60a vpc-038ed6ddc113dfc3f vpc-0f17184ddbfe50ce2) do (
    echo Cleaning VPC %%v
    for /f "tokens=*" %%s in ('aws ec2 describe-subnets --filters "Name=vpc-id,Values=%%v" --query "Subnets[*].SubnetId" --output text') do aws ec2 delete-subnet --subnet-id %%s 2>nul
    for /f "tokens=*" %%r in ('aws ec2 describe-route-tables --filters "Name=vpc-id,Values=%%v" --query "RouteTables[?Associations[0].Main!=true].RouteTableId" --output text') do aws ec2 delete-route-table --route-table-id %%r 2>nul
    for /f "tokens=*" %%i in ('aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=%%v" --query "InternetGateways[*].InternetGatewayId" --output text') do (
        aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %%v 2>nul
        aws ec2 delete-internet-gateway --internet-gateway-id %%i 2>nul
    )
    aws ec2 delete-vpc --vpc-id %%v 2>nul
)

echo === Cleanup complete ===
echo Remaining security groups:
aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId]" --output table