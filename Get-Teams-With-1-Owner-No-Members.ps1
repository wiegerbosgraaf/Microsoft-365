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

# Importeer de benodigde modules
Import-Module MicrosoftTeams
 
# Verbind met Microsoft Teams
Connect-MicrosoftTeams
 
# Haal alle Teams op
$teams = Get-Team
 
# Array om de gewenste Teams op te slaan
$teamsWithOneOwner = @()
 
foreach ($team in $teams) {
    # Haal de leden en eigenaren van elk team op
    $members = Get-TeamUser -GroupId $team.GroupId -Role Member
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
 
    # Controleer of er precies één eigenaar is en geen leden
    if ($owners.Count -eq 1 -and $members.Count -eq 0) {
        $teamInfo = New-Object PSObject -Property @{
            TeamName = $team.DisplayName
            TeamId = $team.GroupId
            Owner = $owners.User
        }
        $teamsWithOneOwner += $teamInfo
    }
}
 
# Exporteer naar CSV
$dataForExport | Export-Csv -Path "TeamsMetEenEigenaarZonderLeden.csv" -NoTypeInformation -Encoding UTF8
 
# Beëindig de verbinding
Disconnect-MicrosoftTeams