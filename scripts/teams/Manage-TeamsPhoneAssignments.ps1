# Script – Manage Teams phone assignments
# This script contains examples for:
# 1. Removing a phone number assignment from a user.
# 2. Finding users associated with a specific phone number.
# 3. Exporting users who have no phone number assigned.
#
# Prerequisites: The MicrosoftTeams PowerShell module must be installed.

# Connect to Microsoft Teams (interactive login required)
Connect-MicrosoftTeams

# Example 1: Remove all phone number assignments for a user
# Set the identity of the user (UserPrincipalName or SIP address)
$Identity = "<user@example.com>"
Remove-CsPhoneNumberAssignment -Identity $Identity -RemoveAll

# Example 2: Find users assigned to a specific phone number
# Replace the phone number with the number you want to search for (E.164 format)
$PhoneNumber = "tel:+<phonenumber>"
Get-CsOnlineUser | Select-Object Name, UserPrincipalName, LineURI | Where-Object { $_.LineURI -eq $PhoneNumber }

# Example 3: Export users without an assigned phone number to a CSV file
# Define the output path for the CSV export
$OutputPath = "C:\Exports\UsersWithoutTeamsPhoneNumber.csv"
Get-CsOnlineUser -AccountType User -Filter { LineURI -eq $null } |
    Select-Object UserPrincipalName, DisplayName, Department |
    Export-Csv -Path $OutputPath -NoTypeInformation
