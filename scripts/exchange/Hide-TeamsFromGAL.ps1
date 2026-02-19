Import-Module ExchangeOnlineManagement

# Connect to Exchange Online (sign-in required)
Connect-ExchangeOnline

# Output folder for reports (modify as needed)
$ExportFolder = "C:\Exports\PowerShell_Reports"
New-Item -Path $ExportFolder -ItemType Directory -Force | Out-Null

# Generate timestamp for filenames
$TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BeforePath = Join-Path $ExportFolder "Teams_GAL_Before_$TimeStamp.csv"
$AfterPath  = Join-Path $ExportFolder "Teams_GAL_After_$TimeStamp.csv"
$LogPath    = Join-Path $ExportFolder "Teams_GAL_Changes_$TimeStamp.csv"

# 1) Determine which Microsoft Teams groups are currently visible in the Global Address List (GAL)
$TeamsVisible = Get-UnifiedGroup -ResultSize Unlimited |
    Where-Object {
        $_.ResourceProvisioningOptions -contains "Team" -and
        $_.HiddenFromAddressListsEnabled -eq $false
    } |
    Select-Object DisplayName, PrimarySmtpAddress, Identity, HiddenFromAddressListsEnabled

# Export list of visible Teams before making changes
$TeamsVisible |
    Select-Object DisplayName, PrimarySmtpAddress, HiddenFromAddressListsEnabled |
    Export-Csv $BeforePath -NoTypeInformation -Encoding UTF8

if (-not $TeamsVisible -or $TeamsVisible.Count -eq 0) {
    Write-Host "No Teams are currently visible in the GAL. No changes made."
    Write-Host "Before export saved to: $BeforePath"
    return
}

# 2) Hide Teams from the GAL by setting HiddenFromAddressListsEnabled to True
$Changes = foreach ($t in $TeamsVisible) {
    try {
        Set-UnifiedGroup -Identity $t.Identity -HiddenFromAddressListsEnabled $true -ErrorAction Stop

        [PSCustomObject]@{
            DisplayName        = $t.DisplayName
            PrimarySmtpAddress = $t.PrimarySmtpAddress
            Action             = "HiddenFromAddressListsEnabled => True"
            Status             = "Success"
            Timestamp          = (Get-Date).ToString("s")
        }
    }
    catch {
        [PSCustomObject]@{
            DisplayName        = $t.DisplayName
            PrimarySmtpAddress = $t.PrimarySmtpAddress
            Action             = "HiddenFromAddressListsEnabled => True"
            Status             = "Failed"
            Error              = $_.Exception.Message
            Timestamp          = (Get-Date).ToString("s")
        }
    }
}

# Export log of changes
$Changes | Export-Csv $LogPath -NoTypeInformation -Encoding UTF8

# 3) Export the list of Teams after changes (for verification)
Get-UnifiedGroup -ResultSize Unlimited |
    Where-Object { $_.ResourceProvisioningOptions -contains "Team" } |
    Select-Object DisplayName, PrimarySmtpAddress, HiddenFromAddressListsEnabled |
    Export-Csv $AfterPath -NoTypeInformation -Encoding UTF8

Write-Host "Finished. Files generated:"
Write-Host "Before export: $BeforePath"
Write-Host "After export : $AfterPath"
Write-Host "Log file    : $LogPath"
