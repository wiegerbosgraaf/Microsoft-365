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

# Installeer de benodigde module (indien niet al geïnstalleerd)
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

# Maak verbinding met Exchange Online
Connect-ExchangeOnline 

# Haal alle shared mailboxen op
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Initialiseer een array om de mailboxen zonder rechten op te slaan
$noPermissionMailboxes = @()

# Loop door elke shared mailbox om de rechten te controleren
foreach ($mailbox in $sharedMailboxes) {
    $permissions = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress

    # Filter de rechten zodat we alleen de standaard en anonieme rechten hebben
    $filteredPermissions = $permissions | Where-Object { $_.User -notin @("NT AUTHORITY\SELF", "NT AUTHORITY\ANONYMOUS LOGON") }

    # Als er geen rechten zijn, voeg de mailbox toe aan de lijst
    if ($filteredPermissions.Count -eq 0) {
        $noPermissionMailboxes += [PSCustomObject]@{
            DisplayName = $mailbox.DisplayName
            PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
        }
    }
}

# Exporteer de mailboxen zonder rechten naar een CSV-bestand
$noPermissionMailboxes | Export-Csv -Path "C:\NoPermissionSharedMailboxes.csv" -NoTypeInformation

# Verbinding met Exchange Online verbreken
Disconnect-ExchangeOnline -Confirm:$false
