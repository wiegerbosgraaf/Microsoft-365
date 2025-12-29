# Script – Manage Teams telephony utilities
# This script provides examples for managing phone assignments in Microsoft Teams.
# Functions included:
# 1. Remove phone number assignments from a user.
# 2. Find users assigned to a specific phone number.
# 3. Export users without any assigned phone number to a CSV file.
#
# Prerequisites:
# - The Microsoft Teams PowerShell module must be installed.
# - You must have appropriate admin permissions to manage phone assignments.

# Connect to Microsoft Teams (interactive login)
Connect-MicrosoftTeams

# 1⃣ Remove phone number assignments from a user
# Set the identity of the user (UserPrincipalName or SIP address)
$UserIdentity = "<user@example.com>"

# Remove all phone number assignments
Remove-CsPhoneNumberAssignment -Identity $UserIdentity -RemoveAll

# 2⃣ Find users assigned to a specific phone number
# Replace the phone number with the one you want to search for (E.164 format)
$TargetPhoneNumber = "tel:+<phonenumber>"

Get-CsOnlineUser |
    Select-Object Name, UserPrincipalName, LineURI |
    Where-Object { $_.LineURI -eq $TargetPhoneNumber }

# 3⃣ Export users without any assigned phone number to a CSV file
# Define the output path for the CSV export
$ExportPath = "C:\Exports\UsersWithoutTeamsPhoneNumber.csv"

Get-CsOnlineUser -AccountType User -Filter { LineURI -eq $null } |
    Select-Object UserPrincipalName, DisplayName, Department |
    Export-Csv -Path $ExportPath -NoTypeInformation
