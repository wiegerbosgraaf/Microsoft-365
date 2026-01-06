<#
.SYNOPSIS
    Synchronize owners of all Teams into a dedicated team.
.DESCRIPTION
    This script uses the Microsoft Teams PowerShell module to find all users who own at least one team in your tenant and ensures they are members of a dedicated "Team Owners Team". If a team owner is not a member or owner of the dedicated team, they will be added. Members of the dedicated team who no longer own any team will be removed.
#>

Import-Module MicrosoftTeams -ErrorAction SilentlyContinue

# Connect to Microsoft Teams (login required)
Connect-MicrosoftTeams

# Name of the administration team that will contain all team owners
$adminTeamName = "Team Owners Team"

# Retrieve the administration team
$adminTeam = Get-Team | Where-Object { $_.DisplayName -eq $adminTeamName }

if (-not $adminTeam) {
    Write-Host "Team '$adminTeamName' not found!" -ForegroundColor Red
    exit
}

# Get current members and owners of the administration team
$adminMembers = Get-TeamUser -GroupId $adminTeam.GroupId | Where-Object { $_.Role -eq "Member" }
$adminOwners  = Get-TeamUser -GroupId $adminTeam.GroupId | Where-Object { $_.Role -eq "Owner" }

# Get all teams in the tenant
$teams = Get-Team

# Build a list of all owners across all teams
$allOwners = @()
foreach ($team in $teams) {
    $owners = Get-TeamUser -GroupId $team.GroupId -Role Owner
    $allOwners += $owners.User
}
# Remove duplicates
$allOwners = $allOwners | Select-Object -Unique

# Add missing owners to the administration team as members
foreach ($owner in $allOwners) {
    if ($adminMembers.User -notcontains $owner -and $adminOwners.User -notcontains $owner) {
        Write-Host "Adding $owner to '$adminTeamName'" -ForegroundColor Green
        Add-TeamUser -GroupId $adminTeam.GroupId -User $owner
    }
}

# Remove members from the administration team who are not owners anymore
foreach ($member in $adminMembers) {
    if ($allOwners -notcontains $member.User) {
        Write-Host "Removing $($member.User) from '$adminTeamName'" -ForegroundColor Yellow
        Remove-TeamUser -GroupId $adminTeam.GroupId -User $member.User
    }
}

Write-Host "Synchronization complete!" -ForegroundColor Cyan
