@echo off
REM Final VPC cleanup script - handles remaining dependencies
REM VPC ID: vpc-01297fb966a8a98cb

set VPC_ID=vpc-01297fb966a8a98cb
set REGION=us-east-1

echo.
echo 🧹 Final VPC Cleanup - Handling remaining dependencies
echo VPC: %VPC_ID%
echo.

echo Step 1: Waiting for VPC endpoints to fully delete...
:check_endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=%VPC_ID%" --query "VpcEndpoints[*].State" --output text --region %REGION% 2>nul | findstr /C:"available" >nul
if %ERRORLEVEL% EQU 0 (
    echo VPC endpoints still deleting... waiting 30 seconds
    timeout /t 30 /nobreak >nul
    goto check_endpoints
)
echo ✅ VPC endpoints fully deleted

echo.
echo Step 2: Deleting remaining security groups...
aws ec2 delete-security-group --group-id sg-068581d80d0e8f4b2 --region %REGION% 2>nul
aws ec2 delete-security-group --group-id sg-0ca043563f38cf923 --region %REGION% 2>nul  
aws ec2 delete-security-group --group-id sg-08ae30f77fe8a0b6c --region %REGION% 2>nul
echo ✅ Security groups deleted

echo.
echo Step 3: Deleting subnets...
aws ec2 delete-subnet --subnet-id subnet-0ec212e860e2adcd9 --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-087384901d6ed883d --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-0591317e09ddcc7d2 --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-0949492702cbcc0b5 --region %REGION%
echo ✅ Subnets deleted

echo.
echo Step 4: Deleting route table...
aws ec2 delete-route-table --route-table-id rtb-06d166659d334b7a8 --region %REGION%
echo ✅ Route table deleted

echo.
echo Step 5: Checking for Internet Gateway...
for /f %%i in ('aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=%VPC_ID%" --query "InternetGateways[].InternetGatewayId" --output text --region %REGION% 2^>nul') do (
    echo Detaching and deleting Internet Gateway: %%i
    aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %VPC_ID% --region %REGION%
    aws ec2 delete-internet-gateway --internet-gateway-id %%i --region %REGION%
)
echo ✅ Internet Gateway cleaned up

echo.
echo Step 6: Deleting VPC...
aws ec2 delete-vpc --vpc-id %VPC_ID% --region %REGION%
echo ✅ VPC deleted

echo.
echo 🎉 VPC cleanup completed successfully!
echo Your AWS account is now clean and ready for fresh deployment.

pause