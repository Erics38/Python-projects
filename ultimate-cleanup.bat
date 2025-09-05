@echo off
echo === ULTIMATE CLEANUP ===

echo Deleting VPC Endpoints...
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-0493c3861946cc498 vpce-0b3e317778eac1680 vpce-0e459d5bf448cccf6 vpce-0808e9913d8649f2c vpce-010da817aee6224b1 vpce-0cc288f0f9afd72fc vpce-0da3dabdd344326b3 vpce-09cf33b0711c0b922 vpce-0b739c810a9ffe66d vpce-033b8c168801c869f

echo Waiting 60 seconds...
ping 127.0.0.1 -n 60 > nul

echo Deleting all subnets...
for /f "tokens=*" %%i in ('aws ec2 describe-subnets --query "Subnets[*].SubnetId" --output text') do aws ec2 delete-subnet --subnet-id %%i

echo Deleting route tables...
for /f "tokens=*" %%i in ('aws ec2 describe-route-tables --query "RouteTables[?Associations[0].Main!=true].RouteTableId" --output text') do aws ec2 delete-route-table --route-table-id %%i

echo Detaching and deleting internet gateways...
for /f "tokens=*" %%i in ('aws ec2 describe-internet-gateways --query "InternetGateways[*].InternetGatewayId" --output text') do (
    for /f "tokens=*" %%j in ('aws ec2 describe-internet-gateways --internet-gateway-ids %%i --query "InternetGateways[*].Attachments[*].VpcId" --output text') do aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %%j
    aws ec2 delete-internet-gateway --internet-gateway-id %%i
)

echo Deleting NAT gateways...
for /f "tokens=*" %%i in ('aws ec2 describe-nat-gateways --query "NatGateways[*].NatGatewayId" --output text') do aws ec2 delete-nat-gateway --nat-gateway-id %%i

echo Waiting another 30 seconds...
ping 127.0.0.1 -n 30 > nul

echo Deleting security groups...
for /f "tokens=2" %%i in ('aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].[GroupName,GroupId]" --output text') do aws ec2 delete-security-group --group-id %%i

echo Deleting VPCs...
for /f "tokens=*" %%i in ('aws ec2 describe-vpcs --query "Vpcs[?IsDefault!=true].VpcId" --output text') do aws ec2 delete-vpc --vpc-id %%i

echo === FINAL STATUS ===
aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId]" --output table