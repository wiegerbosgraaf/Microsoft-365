# ✅ Wat doet dit script?
# Zoekt het team "Teameigenaren Teams" op.
# Als het niet bestaat, stopt het script.
# Haalt alle huidige leden en eigenaren van "Teameigenaren Teams" op.
# Zoekt alle Teams-eigenaren binnen de M365-omgeving.
# Vergelijkt de lijsten en voert acties uit:
#   - Ontbrekende eigenaren worden als lid toegevoegd aan "Teameigenaren Teams".
#   - Niet-eigenaren worden verwijderd uit "Teameigenaren Teams".
# Geeft real-time statusupdates in de console.

# Laad de MicrosoftTeams-module
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue

# Maak verbinding met Microsoft Teams (inloggen vereist)
Connect-MicrosoftTeams

# Naam van het beheerders-team
$adminTeamName = "Teameigenaren Teams"

# Haal het beheerders-team op
$adminTeam = Get-Team | Where-Object { $_.DisplayName -eq $adminTeamName }

if (-not $adminTeam) {
    Write-Host "Team '$adminTeamName' niet gevonden!" -ForegroundColor Red
    exit
}

# Haal huidige leden van het beheerders-team op
$adminMembers = Get-TeamUser -GroupId $adminTeam.GroupId | Where-Object { $_.Role -eq "Member" }
$adminOwners  = Get-TeamUser -GroupId $adminTeam.GroupId | Where-Object { $_.Role -eq "Owner" }

# Haal alle teams op
$teams = Get-Team

# Maak een lijst met ALLE eigenaren van ALLE teams
$allOwners = @()
foreach ($team in $teams) {
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
    $allOwners += $owners.User
}
$allOwners = $allOwners | Select-Object -Unique  # Verwijder dubbele waarden

# 1️⃣ Toevoegen van ontbrekende eigenaren aan 'Teameigenaren Teams'
foreach ($owner in $allOwners) {
    if ($adminMembers.User -notcontains $owner -and $adminOwners.User -notcontains $owner) {
        Write-Host "✅ $owner wordt toegevoegd aan '$adminTeamName'" -ForegroundColor Green
        Add-TeamUser -GroupId $adminTeam.GroupId -User $owner
    }
}

# 2️⃣ Verwijderen van niet-eigenaren uit 'Teameigenaren Teams'
foreach ($member in $adminMembers) {
    if ($allOwners -notcontains $member.User) {
        Write-Host "❌ $($member.User) wordt verwijderd uit '$adminTeamName'" -ForegroundColor Red
        Remove-TeamUser -GroupId $adminTeam.GroupId -User $member.User
    }
}

Write-Host "✅ Synchronisatie voltooid!" -ForegroundColor Cyan
