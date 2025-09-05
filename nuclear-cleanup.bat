@echo off
echo ========================================
echo    NUCLEAR OPTION - DELETE EVERYTHING
echo ========================================
echo WARNING: This will attempt to delete ALL resources in your AWS account!
echo This includes resources NOT related to this project!
echo.
echo Press Ctrl+C to cancel, or
pause

echo === PHASE 1: Delete all ECS services and tasks ===
for /f "tokens=*" %%i in ('aws ecs list-clusters --query "clusterArns[*]" --output text') do (
    echo Deleting services in cluster %%i
    for /f "tokens=*" %%j in ('aws ecs list-services --cluster %%i --query "serviceArns[*]" --output text') do (
        aws ecs update-service --cluster %%i --service %%j --desired-count 0
        aws ecs delete-service --cluster %%i --service %%j --force
    )
    aws ecs delete-cluster --cluster %%i
)

echo === PHASE 2: Delete all load balancers ===
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text') do (
    aws elbv2 delete-load-balancer --load-balancer-arn %%i
)

echo === PHASE 3: Delete all RDS instances ===
for /f "tokens=*" %%i in ('aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output text') do (
    aws rds delete-db-instance --db-instance-identifier %%i --skip-final-snapshot --delete-automated-backups
)

echo === PHASE 4: Wait for resources to delete ===
echo Waiting 5 minutes for resources to delete...
timeout /t 300 /nobreak

echo === PHASE 5: Force delete all security groups (except default) ===
for /f "tokens=2" %%i in ('aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].[GroupName,GroupId]" --output text') do (
    echo Attempting to delete security group %%i
    aws ec2 delete-security-group --group-id %%i 2>nul
)

echo === PHASE 6: Delete all subnets ===
for /f "tokens=*" %%i in ('aws ec2 describe-subnets --query "Subnets[*].SubnetId" --output text') do (
    aws ec2 delete-subnet --subnet-id %%i 2>nul
)

echo === PHASE 7: Delete internet gateways ===
for /f "tokens=*" %%i in ('aws ec2 describe-internet-gateways --query "InternetGateways[*].InternetGatewayId" --output text') do (
    for /f "tokens=*" %%j in ('aws ec2 describe-internet-gateways --internet-gateway-ids %%i --query "InternetGateways[*].Attachments[*].VpcId" --output text') do (
        aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %%j 2>nul
    )
    aws ec2 delete-internet-gateway --internet-gateway-id %%i 2>nul
)

echo === PHASE 8: Delete route tables ===
for /f "tokens=*" %%i in ('aws ec2 describe-route-tables --query "RouteTables[?Associations[0].Main!=true].RouteTableId" --output text') do (
    aws ec2 delete-route-table --route-table-id %%i 2>nul
)

echo === PHASE 9: Delete NAT gateways ===
for /f "tokens=*" %%i in ('aws ec2 describe-nat-gateways --query "NatGateways[*].NatGatewayId" --output text') do (
    aws ec2 delete-nat-gateway --nat-gateway-id %%i 2>nul
)

echo === PHASE 10: Release Elastic IPs ===
for /f "tokens=*" %%i in ('aws ec2 describe-addresses --query "Addresses[*].AllocationId" --output text') do (
    aws ec2 release-address --allocation-id %%i 2>nul
)

echo === PHASE 11: Delete VPCs (except default) ===
for /f "tokens=*" %%i in ('aws ec2 describe-vpcs --query "Vpcs[?IsDefault!=true].VpcId" --output text') do (
    aws ec2 delete-vpc --vpc-id %%i 2>nul
)

echo === PHASE 12: Delete remaining AWS resources ===
echo Deleting CloudWatch log groups...
for /f "tokens=*" %%i in ('aws logs describe-log-groups --query "logGroups[*].logGroupName" --output text') do (
    aws logs delete-log-group --log-group-name %%i 2>nul
)

echo Deleting Secrets Manager secrets...
for /f "tokens=*" %%i in ('aws secretsmanager list-secrets --query "SecretList[*].ARN" --output text') do (
    aws secretsmanager delete-secret --secret-id %%i --force-delete-without-recovery 2>nul
)

echo Deleting WAF Web ACLs...
for /f "tokens=*" %%i in ('aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[*].ARN" --output text') do (
    aws wafv2 delete-web-acl --scope REGIONAL --id %%i 2>nul
)

echo.
echo ========================================
echo    NUCLEAR CLEANUP COMPLETE
echo ========================================
echo.
echo Remaining resources (should be minimal):
aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId]" --output table
echo.
aws ec2 describe-vpcs --query "Vpcs[*].[VpcId,IsDefault,State]" --output table