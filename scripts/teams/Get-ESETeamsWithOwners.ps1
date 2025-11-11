<#

Copyright © 2024 Wieger Bosgraaf. All rights reserved.

This PowerShell script, along with all its associated files and documentation, is protected by copyright law and international treaties. 
Wieger Bosgraaf ("the Author") retains full ownership and intellectual property rights to this work. Unauthorized use, reproduction, 
or distribution of this script, in whole or in part, without the express written permission of the Author, is strictly prohibited.

Last Updated: March 7, 2024

Permission for Use:
The Author grants you a non-exclusive, non-transferable license to use this script for personal or internal business purposes only, provided that:

1. You do not remove or alter the copyright notice, including the Author's name and the last updated date, in any copies or derivative works.
2. You do not distribute the script for commercial gain or public distribution without obtaining explicit written permission from the Author.
3. You acknowledge that the script is provided "as-is" without any warranty, express or implied, and the Author shall not be liable for any damages arising from the use of this script.

For inquiries regarding licensing, customization, or other permissions, please contact Wieger Bosgraaf through his website: https://www.wiegerbosgraaf.nl/ or 
his LinkedIn page: https://www.linkedin.com/in/wiegerbosgraaf/.

The Author reserves the right to take legal action against any unauthorized use or distribution of this script that violates this copyright notice and the terms outlined herein.

#>

# Importeer de MicrosoftTeams-module
Import-Module MicrosoftTeams

# Maak verbinding met Microsoft Teams
Connect-MicrosoftTeams

# Haal alle teams op
$teams = Get-Team

# Filter teams met '-ESE' in hun naam
$eseTeams = $teams | Where-Object { $_.DisplayName -like '*-ESE*' }

# Bereid gegevens voor export voor
$exportData = foreach ($team in $eseTeams) {
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
    $ownerNames = ($owners | ForEach-Object { $_.Name }) -join ', '
    $ownerUserPrincipalNames = ($owners | ForEach-Object { $_.UserPrincipalName }) -join ', '

    [PSCustomObject]@{
        "Team Name" = $team.DisplayName
        "Team ID" = $team.GroupId
        "Owner Names" = $ownerNames
        "Owner UserPrincipalNames" = $ownerUserPrincipalNames
    }
}

# Exporteer gegevens naar CSV
$exportData | Export-Csv -Path "./Teams-ESE-Met-Eigenaren.csv" -NoTypeInformation

# Verbreek de verbinding met Microsoft Teams
Disconnect-MicrosoftTeams
