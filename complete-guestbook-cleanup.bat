@echo off
REM Complete Guestbook Cleanup - All VPCs and Resources
REM This handles multiple VPCs if they exist

set REGION=us-east-1
set GUESTBOOK_VPC=vpc-01297fb966a8a98cb

echo.
echo 🧹 COMPLETE GUESTBOOK CLEANUP
echo ========================================
echo.
echo This will completely remove ALL guestbook resources:
echo - VPC: %GUESTBOOK_VPC%
echo - All 4 subnets in the guestbook VPC  
echo - All security groups
echo - All route tables
echo - Internet gateways
echo - VPC endpoints
echo.
set /p CONFIRM="Type 'CLEAN' to proceed with complete cleanup: "

if not "%CONFIRM%"=="CLEAN" (
    echo Cleanup cancelled.
    pause
    exit /b 0
)

echo.
echo 🚨 Starting complete guestbook cleanup...

REM Step 1: Wait for any pending VPC endpoint deletions
echo.
echo Step 1: Checking VPC endpoint status...
:wait_endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=%GUESTBOOK_VPC%" --query "VpcEndpoints[*].{Id:VpcEndpointId,State:State}" --output table --region %REGION% 2>nul | findstr -c "available" >nul
if %ERRORLEVEL% EQU 0 (
    echo VPC endpoints still active, waiting 15 seconds...
    timeout /t 15 /nobreak >nul
    goto wait_endpoints
)
echo ✅ VPC endpoints ready for cleanup

REM Step 2: Force delete any remaining VPC endpoints
echo.
echo Step 2: Force deleting any remaining VPC endpoints...
for /f %%i in ('aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=%GUESTBOOK_VPC%" --query "VpcEndpoints[].VpcEndpointId" --output text --region %REGION% 2^>nul') do (
    if not "%%i"=="None" (
        echo Deleting VPC endpoint: %%i
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids %%i --region %REGION% >nul 2>&1
    )
)

REM Wait for endpoints to actually delete
echo Waiting 30 seconds for VPC endpoints to fully delete...
timeout /t 30 /nobreak >nul

REM Step 3: Delete security groups (retry multiple times for dependencies)
echo.
echo Step 3: Deleting security groups...
for /L %%i in (1,1,3) do (
    echo Attempt %%i of 3...
    aws ec2 delete-security-group --group-id sg-068581d80d0e8f4b2 --region %REGION% >nul 2>&1
    aws ec2 delete-security-group --group-id sg-03cd0ad0e439a8976 --region %REGION% >nul 2>&1
    aws ec2 delete-security-group --group-id sg-0b0799cf40089b970 --region %REGION% >nul 2>&1
    aws ec2 delete-security-group --group-id sg-0ca043563f38cf923 --region %REGION% >nul 2>&1
    aws ec2 delete-security-group --group-id sg-011a3c6516eae9afb --region %REGION% >nul 2>&1
    aws ec2 delete-security-group --group-id sg-08ae30f77fe8a0b6c --region %REGION% >nul 2>&1
    timeout /t 10 /nobreak >nul
)
echo ✅ Security groups cleanup completed

REM Step 4: Delete subnets
echo.
echo Step 4: Deleting all 4 guestbook subnets...
aws ec2 delete-subnet --subnet-id subnet-0ec212e860e2adcd9 --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-087384901d6ed883d --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-0591317e09ddcc7d2 --region %REGION%
aws ec2 delete-subnet --subnet-id subnet-0949492702cbcc0b5 --region %REGION%
echo ✅ All 4 subnets deleted

REM Step 5: Delete route tables
echo.
echo Step 5: Deleting route tables...
aws ec2 delete-route-table --route-table-id rtb-06d166659d334b7a8 --region %REGION%
echo ✅ Route tables deleted

REM Step 6: Detach and delete Internet Gateway
echo.
echo Step 6: Cleaning up Internet Gateway...
for /f %%i in ('aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=%GUESTBOOK_VPC%" --query "InternetGateways[].InternetGatewayId" --output text --region %REGION% 2^>nul') do (
    if not "%%i"=="None" (
        echo Detaching Internet Gateway: %%i
        aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %GUESTBOOK_VPC% --region %REGION%
        echo Deleting Internet Gateway: %%i  
        aws ec2 delete-internet-gateway --internet-gateway-id %%i --region %REGION%
    )
)
echo ✅ Internet Gateway cleaned up

REM Step 7: Delete the VPC
echo.
echo Step 7: Deleting guestbook VPC...
aws ec2 delete-vpc --vpc-id %GUESTBOOK_VPC% --region %REGION%
echo ✅ VPC deleted

REM Step 8: Clean up other guestbook resources
echo.
echo Step 8: Cleaning up other AWS resources...

REM Secrets Manager
aws secretsmanager delete-secret --secret-id "guestbook-demo-db-credentials" --force-delete-without-recovery --region %REGION% >nul 2>&1

REM CloudWatch logs
aws logs delete-log-group --log-group-name "/aws/ecs/guestbook-demo-cluster-app" --region %REGION% >nul 2>&1
aws logs delete-log-group --log-group-name "/aws/waf/demo-guestbook" --region %REGION% >nul 2>&1

REM IAM roles (detach policies first)
for %%r in (
    "guestbook-demo-ecs-execution-role"
    "guestbook-demo-ecs-task-role" 
    "demo-security-headers-lambda-role"
) do (
    REM Detach managed policies
    for /f %%p in ('aws iam list-attached-role-policies --role-name %%r --query "AttachedPolicies[].PolicyArn" --output text --region %REGION% 2^>nul') do (
        if not "%%p"=="None" (
            aws iam detach-role-policy --role-name %%r --policy-arn %%p --region %REGION% >nul 2>&1
        )
    )
    REM Delete inline policies  
    for /f %%i in ('aws iam list-role-policies --role-name %%r --query "PolicyNames[]" --output text --region %REGION% 2^>nul') do (
        if not "%%i"=="None" (
            aws iam delete-role-policy --role-name %%r --policy-name %%i --region %REGION% >nul 2>&1
        )
    )
    REM Delete role
    aws iam delete-role --role-name %%r --region %REGION% >nul 2>&1
)

echo ✅ Supporting resources cleaned up

echo.
echo 🎉 COMPLETE CLEANUP FINISHED!
echo ========================================
echo.
echo Your AWS account is now completely clean:
echo ✅ VPC %GUESTBOOK_VPC% deleted
echo ✅ All 4 subnets removed  
echo ✅ All 6 security groups removed
echo ✅ Route tables and Internet Gateway removed
echo ✅ VPC endpoints removed
echo ✅ Supporting resources (secrets, logs, IAM) cleaned up
echo.
echo 🚀 Ready for fresh simplified deployment!
echo.

pause