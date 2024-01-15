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

# Importeer de Azure Active Directory PowerShell-module
Import-Module AzureAD

# Verbind met Azure AD
$Credentials = Get-Credential
Connect-AzureAD -Credential $Credentials

# Haal alle Azure AD gastgebruikers op
$guestUsers = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true

# De datum van één jaar geleden in een correct formaat voor de filter
$oneYearAgo = (Get-Date).AddYears(-1).ToString("yyyy-MM-dd")

foreach ($user in $guestUsers) {
    # Haal de laatste aanmeldingsdatum op met een correcte filter syntax
    $signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '$($user.ObjectId)' and createdDateTime ge $oneYearAgo" -Top 1

    # Controleer of de gebruiker langer dan een jaar inactief is
    if ($signInLogs.Count -eq 0) {
        $dataForExport += [PSCustomObject]@{
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            ObjectId = $user.ObjectId
        }
    }
}


# Exporteer naar CSV
$dataForExport | Export-Csv -Path "InactiveGuestUsers.csv" -NoTypeInformation -Encoding UTF8

# Verbreek de verbinding met Azure AD
Disconnect-AzureAD
