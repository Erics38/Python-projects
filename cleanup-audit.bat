@echo off
echo === SECURITY GROUPS AUDIT ===
echo.
echo All Security Groups:
aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId,Description,VpcId]" --output table

echo.
echo === PROJECT-RELATED SECURITY GROUPS ===
aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, 'guestbook') || contains(GroupName, 'docker') || contains(Description, 'guestbook')].[GroupName,GroupId,Description,VpcId]" --output table

echo.
echo === VPCs ===
aws ec2 describe-vpcs --query "Vpcs[*].[VpcId,CidrBlock,State,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo === ECS CLUSTERS ===
aws ecs list-clusters --query "clusterArns[*]" --output table

echo.
echo === LOAD BALANCERS ===
aws elbv2 describe-load-balancers --query "LoadBalancers[*].[LoadBalancerName,LoadBalancerArn,State.Code]" --output table

echo.
echo === RDS INSTANCES ===
aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]" --output table