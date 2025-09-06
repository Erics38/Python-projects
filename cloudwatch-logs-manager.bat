@echo off
REM CloudWatch Logs Management Script for Windows with Git Bash
REM Workaround for Windows path conversion issues

echo CloudWatch Logs Manager for ECS
echo ==================================

set REGION=us-east-1
set LOG_GROUP_BASE=/aws/ecs/guestbook-demo

REM Function to create log group
:create_log_group
echo Creating log group: %LOG_GROUP_BASE%
set MSYS_NO_PATHCONV=1
aws logs create-log-group --log-group-name "%LOG_GROUP_BASE%" --region %REGION%
if %ERRORLEVEL% equ 0 (
    echo Log group created successfully
    echo Setting retention policy to 7 days...
    aws logs put-retention-policy --log-group-name "%LOG_GROUP_BASE%" --retention-in-days 7 --region %REGION%
    if %ERRORLEVEL% equ 0 (
        echo Retention policy set successfully
    ) else (
        echo Failed to set retention policy
    )
) else (
    echo Failed to create log group or it may already exist
)
goto list_log_groups

:list_log_groups
echo.
echo Current log groups:
set MSYS_NO_PATHCONV=1
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/guestbook" --region %REGION% --query "logGroups[].{Name:logGroupName,RetentionDays:retentionInDays,CreatedTime:creationTime}" --output table
goto end

:delete_log_group
echo WARNING: This will delete the log group and all its data!
set /p confirm=Are you sure you want to delete %LOG_GROUP_BASE%? (y/N): 
if /i "%confirm%"=="y" (
    set MSYS_NO_PATHCONV=1
    aws logs delete-log-group --log-group-name "%LOG_GROUP_BASE%" --region %REGION%
    if %ERRORLEVEL% equ 0 (
        echo Log group deleted successfully
    ) else (
        echo Failed to delete log group
    )
) else (
    echo Deletion cancelled
)
goto end

:help
echo Usage:
echo   %0 create   - Create the ECS log group with 7-day retention
echo   %0 list     - List all ECS-related log groups
echo   %0 delete   - Delete the ECS log group (with confirmation)
echo   %0 help     - Show this help message
echo.
echo Note: This script uses MSYS_NO_PATHCONV=1 to prevent Git Bash path conversion issues
goto end

REM Main logic
if "%1"=="create" goto create_log_group
if "%1"=="list" goto list_log_groups  
if "%1"=="delete" goto delete_log_group
if "%1"=="help" goto help
if "%1"=="" goto list_log_groups

echo Invalid argument: %1
goto help

:end
echo.
echo CloudWatch Logs Manager completed