# CloudWatch Logs Management Script for Windows PowerShell
# No path conversion issues with PowerShell

param(
    [Parameter(Position=0)]
    [ValidateSet("create", "list", "delete", "help")]
    [string]$Action = "list",
    
    [string]$Region = "us-east-1",
    [string]$LogGroup = "/aws/ecs/guestbook-demo"
)

function Write-Header {
    Write-Host "CloudWatch Logs Manager for ECS" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
}

function Create-LogGroup {
    Write-Host "Creating log group: $LogGroup" -ForegroundColor Yellow
    
    try {
        aws logs create-log-group --log-group-name $LogGroup --region $Region 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Log group created successfully" -ForegroundColor Green
            
            Write-Host "Setting retention policy to 7 days..." -ForegroundColor Yellow
            aws logs put-retention-policy --log-group-name $LogGroup --retention-in-days 7 --region $Region
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Retention policy set successfully" -ForegroundColor Green
            } else {
                Write-Host "Failed to set retention policy" -ForegroundColor Red
            }
        } else {
            Write-Host "Failed to create log group (it may already exist)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error creating log group: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function List-LogGroups {
    Write-Host "Current ECS log groups:" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $result = aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/guestbook" --region $Region --output json | ConvertFrom-Json
        
        if ($result.logGroups.Count -gt 0) {
            $result.logGroups | Format-Table @{
                Name = "Log Group Name"; Expression = { $_.logGroupName }
            }, @{
                Name = "Retention (Days)"; Expression = { 
                    if ($_.retentionInDays) { $_.retentionInDays } else { "Never expires" }
                }
            }, @{
                Name = "Created"; Expression = { 
                    [DateTimeOffset]::FromUnixTimeMilliseconds($_.creationTime).ToString("yyyy-MM-dd HH:mm:ss")
                }
            }, @{
                Name = "Size (Bytes)"; Expression = { $_.storedBytes }
            } -AutoSize
        } else {
            Write-Host "No ECS log groups found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error listing log groups: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Delete-LogGroup {
    Write-Host "WARNING: This will delete the log group and all its data!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure you want to delete '$LogGroup'? (y/N)"
    
    if ($confirm.ToLower() -eq 'y') {
        try {
            aws logs delete-log-group --log-group-name $LogGroup --region $Region
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Log group deleted successfully" -ForegroundColor Green
            } else {
                Write-Host "Failed to delete log group" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error deleting log group: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Deletion cancelled" -ForegroundColor Yellow
    }
}

function Show-Help {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\cloudwatch-logs-manager.ps1 create   - Create the ECS log group with 7-day retention"
    Write-Host "  .\cloudwatch-logs-manager.ps1 list     - List all ECS-related log groups"
    Write-Host "  .\cloudwatch-logs-manager.ps1 delete   - Delete the ECS log group (with confirmation)"
    Write-Host "  .\cloudwatch-logs-manager.ps1 help     - Show this help message"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Cyan
    Write-Host "  -Region <region>     AWS region (default: us-east-1)"
    Write-Host "  -LogGroup <name>     Log group name (default: /aws/ecs/guestbook-demo)"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\cloudwatch-logs-manager.ps1 create"
    Write-Host "  .\cloudwatch-logs-manager.ps1 list -Region us-west-2"
    Write-Host "  .\cloudwatch-logs-manager.ps1 delete -LogGroup '/aws/ecs/my-app'"
}

# Main execution
Write-Header

switch ($Action) {
    "create" { Create-LogGroup; List-LogGroups }
    "list" { List-LogGroups }
    "delete" { Delete-LogGroup }
    "help" { Show-Help }
    default { Show-Help }
}

Write-Host ""
Write-Host "CloudWatch Logs Manager completed" -ForegroundColor Cyan