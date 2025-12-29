# Script – Reset Teams Voice Routing Policy
# This script resets the Voice Routing Policy for a list of users in Microsoft Teams to the default (Global) policy.
#
# Prerequisites:
# - The Microsoft Teams PowerShell module must be installed.
# - You must be a Teams administrator with permission to manage voice routing policies.
# - Prepare a CSV file containing the users to reset. The CSV should have a header line and at least a column 'Username' with UserPrincipalName values.
#   Example:
#     DisplayName,Username,PhoneNumber
#     Alex Example,alex@example.com,+3123456789
#     ...
#
# Note: Ensure a change request or proper approval is in place before executing this script in a production environment.

# Connect to Microsoft Teams (interactive sign-in)
Connect-MicrosoftTeams

# Path to the CSV file containing user information
$CsvPath = "C:\Temp\UsersList.csv"

# Import user data from CSV
$UserData = Import-Csv -Path $CsvPath

# Optional: Inspect the imported data
$UserData.Count                              # Show number of records
$UserData[0..2]                              # Show first three records (dataset index starts at 0)
$UserData[0,1]                               # Show the second record
$UserData[0..2] | Format-Table -AutoSize -Property DisplayName, Username, PhoneNumber

# Loop through each user and reset their voice routing policy to Global (Default)
foreach ($record in $UserData) {
    $UserPrincipalName = $record.Username
    Write-Host "Resetting voice routing policy for $UserPrincipalName" -ForegroundColor Green
    Grant-CsOnlineVoiceRoutingPolicy -Identity $UserPrincipalName -PolicyName $Null
}

Write-Host "Voice routing policy reset completed for all users." -ForegroundColor Cyan
