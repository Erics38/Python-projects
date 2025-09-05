@echo off
echo === VPC CLEANUP ===
echo.
echo WARNING: This will delete VPCs and associated networking resources!
echo Make sure all EC2 instances, load balancers, and RDS instances are deleted first!
echo.
pause

echo Deleting guestbook VPCs...
echo.

REM First delete subnets, route tables, internet gateways, etc. for each VPC
echo Cleaning up VPC: vpc-0899032133b559e32
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0899032133b559e32" --query "Subnets[*].SubnetId" --output text > temp_subnets.txt
for /f %%i in (temp_subnets.txt) do aws ec2 delete-subnet --subnet-id %%i

echo Cleaning up VPC: vpc-095586e614ea1a60a
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-095586e614ea1a60a" --query "Subnets[*].SubnetId" --output text > temp_subnets.txt
for /f %%i in (temp_subnets.txt) do aws ec2 delete-subnet --subnet-id %%i

echo Cleaning up VPC: vpc-038ed6ddc113dfc3f
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-038ed6ddc113dfc3f" --query "Subnets[*].SubnetId" --output text > temp_subnets.txt
for /f %%i in (temp_subnets.txt) do aws ec2 delete-subnet --subnet-id %%i

echo Cleaning up VPC: vpc-0f17184ddbfe50ce2
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0f17184ddbfe50ce2" --query "Subnets[*].SubnetId" --output text > temp_subnets.txt
for /f %%i in (temp_subnets.txt) do aws ec2 delete-subnet --subnet-id %%i

REM Delete the VPCs (keep default VPC)
aws ec2 delete-vpc --vpc-id vpc-0899032133b559e32
aws ec2 delete-vpc --vpc-id vpc-095586e614ea1a60a
aws ec2 delete-vpc --vpc-id vpc-038ed6ddc113dfc3f
aws ec2 delete-vpc --vpc-id vpc-0f17184ddbfe50ce2

del temp_subnets.txt

echo.
echo VPC cleanup complete!
echo.
echo Final step: Check remaining resources with: aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId]" --output table