<#
Copyright © 2024 Wieger Bosgraaf. All rights reserved.

This PowerShell script, along with all its associated files and documentation, is protected by copyright law and international treaties. 
Wieger Bosgraaf ("the Author") retains full ownership and intellectual property rights to this work. Unauthorized use, reproduction, 
or distribution of this script, in whole or in part, without the express written permission of the Author, is strictly prohibited.

Last Updated: January 15, 2024

Permission for Use:
The Author grants you a non-exclusive, non-transferable license to use this script for personal or internal business purposes only, provided that:

1. You do not remove or alter the copyright notice, including the Author's name and the last updated date, in any copies or derivative works.
2. You do not distribute the script for commercial gain or public distribution without obtaining explicit written permission from the Author.
3. You acknowledge that the script is provided "as-is" without any warranty, express or implied, and the Author shall not be liable for any damages arising from the use of this script.

For inquiries regarding licensing, customization, or other permissions, please contact Wieger Bosgraaf through his website: https://www.wiegerbosgraaf.nl/ or 
his LinkedIn page: https://www.linkedin.com/in/wiegerbosgraaf/.

The Author reserves the right to take legal action against any unauthorized use or distribution of this script that violates this copyright notice and the terms outlined herein.

#>

# Connect to Exchange Online
Connect-ExchangeOnline 

# Collecting resource mailboxes (Rooms and Equipment)
$resourceMailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox -ResultSize Unlimited

# Preparing the export
$results = @()

foreach ($mailbox in $resourceMailboxes) {
    try {
        $mailboxStats = Get-MailboxStatistics -Identity $mailbox.PrimarySmtpAddress
        $lastLogonTime = $mailboxStats.LastLogonTime
        $mailboxSize = $mailboxStats.TotalItemSize

        # Adding the mailbox info to the results
        $results += New-Object PSObject -Property @{
            MailboxName        = $mailbox.DisplayName
            PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
            MailboxType        = $mailbox.RecipientTypeDetails
            MailboxSize        = $mailboxSize
            LastActivity       = $mailboxStats.LastUserActionTime
            LastLogonTime      = $lastLogonTime
        }
    } catch {
        Write-Host "There was a problem retrieving data for mailbox: $($mailbox.DisplayName)"
    }
}

# Exporting to CSV
$results | Export-Csv -Path "Resource-Mailbox-Data-FP.csv" -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
