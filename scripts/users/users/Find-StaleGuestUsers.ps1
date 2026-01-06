<#
.SYNOPSIS
    Finds guest user accounts older than a specified number of days and optionally removes them.
.DESCRIPTION
    This script uses Azure AD and Microsoft Graph to enumerate all guest user accounts in your tenant. It reports accounts older than the threshold and with no recent sign-in activity and not members of any Microsoft 365 groups. You can choose to generate a full report, a report of stale accounts, or a report and remove those accounts.
.PARAMETER AgeThreshold
    Number of days to consider an account stale. Defaults to 365.
#>

param(
    [int]$AgeThreshold = 365
)

# Ensure required modules are installed
if (-not (Get-Module -ListAvailable -Name "AzureADPreview")) {
    Install-Module AzureADPreview -AllowClobber -Force -Scope CurrentUser
}
if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph")) {
    Install-Module Microsoft.Graph -AllowClobber -Force -Scope CurrentUser
}

# Import modules
Import-Module AzureADPreview -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop

# Connect to services
Write-Host "Connecting to Azure AD..." -ForegroundColor Cyan
Connect-AzureAD -ErrorAction Stop
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All"

# Use beta profile to access signInActivity
Select-MgProfile -Name "beta"

# Prepare output directory in the user's temp folder
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GuestReports"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Display menu
Write-Host "Select an option:" -ForegroundColor Yellow
Write-Host "1. Create report for all guest users"
Write-Host "2. Create report for stale guest users (Age >= $AgeThreshold days and no recent activity)"
Write-Host "3. Create report and remove stale guest users"
$choice = Read-Host "Enter choice (1/2/3)"

# Retrieve all guest accounts in the tenant
$guestUsers = Get-AzureADUser -All $true -Filter "userType eq 'Guest'" | Sort-Object DisplayName

function Get-StaleGuestUsers {
    param([object[]]$Guests)

    $stale = @()
    foreach ($Guest in $Guests) {
        $ageDays = (New-TimeSpan -Start $Guest.RefreshTokensValidFromDateTime -End (Get-Date)).Days

        if ($ageDays -ge $AgeThreshold) {
            # Skip if the guest is a member of any group
            $groups = Get-AzureADUserMembership -ObjectId $Guest.ObjectId
            if ($groups.Count -eq 0) {
                # Check last sign-in via Graph
                $signInInfo = Get-MgUser -UserId $Guest.ObjectId -Property "signInActivity"
                $lastSign = $signInInfo.SignInActivity.LastSignInDateTime
                $inactive = $false
                if ($null -ne $lastSign) {
                    $lastSignDays = (New-TimeSpan -Start $lastSign -End (Get-Date)).Days
                    if ($lastSignDays -ge $AgeThreshold) {
                        $inactive = $true
                    }
                } else {
                    $inactive = $true
                }
                if ($inactive) {
                    $stale += [PSCustomObject]@{
                        Mail       = $Guest.Mail
                        DisplayName = $Guest.DisplayName
                        AgeDays     = $ageDays
                        LastSignIn  = if ($lastSign) { $lastSign } else { "None" }
                        ObjectId    = $Guest.ObjectId
                    }
                }
            }
        }
    }
    return $stale
}

$reportFile = Join-Path -Path $outputDir -ChildPath ("GuestReport_{0}.csv" -f $timestamp)
$staleFile  = Join-Path -Path $outputDir -ChildPath ("StaleGuests_{0}.csv" -f $timestamp)

switch ($choice) {
    "1" {
        # Export all guest users
        $guestUsers | Select-Object DisplayName, Mail, RefreshTokensValidFromDateTime, ObjectId | Export-Csv -NoTypeInformation -Path $reportFile
        Write-Host "Report created: $reportFile" -ForegroundColor Green
    }
    "2" {
        $stale = Get-StaleGuestUsers -Guests $guestUsers
        $stale | Export-Csv -NoTypeInformation -Path $staleFile
        Write-Host "Stale guest report created: $staleFile" -ForegroundColor Green
    }
    "3" {
        $stale = Get-StaleGuestUsers -Guests $guestUsers
        $stale | Export-Csv -NoTypeInformation -Path $staleFile
        Write-Host "Stale guest report created: $staleFile" -ForegroundColor Green
        $confirm = Read-Host "Do you want to remove these guest accounts? (y/n)"
        if ($confirm -eq "y") {
            foreach ($account in $stale) {
                Write-Host "Removing guest user $($account.DisplayName)..." -ForegroundColor Yellow
                Remove-AzureADUser -ObjectId $account.ObjectId -Confirm:$false
            }
            Write-Host "Removal complete." -ForegroundColor Green
        } else {
            Write-Host "Deletion aborted." -ForegroundColor Yellow
        }
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    }
}

# Disconnect services
Disconnect-AzureAD -Confirm:$false
Disconnect-MgGraph -Confirm:$false
