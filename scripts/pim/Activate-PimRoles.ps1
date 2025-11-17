# Example usage:
# .\Activate-PimRoles.ps1 -UserPrincipalName "user@domain.com" -RoleNames @('Teams Administrator','Exchange Administrator','SharePoint Administrator') -RefreshRoleActivation

param (
    [string]$UserPrincipalName,
    [string[]]$RoleNames,
    [switch]$RefreshRoleActivation,
    [switch]$ShowAssignment
)

# Set Error Action - Possible choices: Stop, SilentlyContinue
$ErrorActionPreference = 'Stop'

# Check if the Azure AD Preview module is installed.
if (-not (Get-Module -ListAvailable -Name 'AzureADPreview')) {
    Write-Error -Exception "The AzureADPreview PowerShell module is not installed. Please run 'Install-Module AzureADPreview -Force' as an admin and try again." -ErrorAction Stop
} else {
    Write-Host 'The AzureADPreview PowerShell module is installed'
}

# Make sure AzureADPreview is the loaded PowerShell module even if AzureAD is installed.
Write-Host 'Import modules we need'
Remove-Module AzureAD -ErrorAction SilentlyContinue
Import-Module AzureADPreview

# Connect AzureAD
try {
    $tenantDetail = Get-AzureADTenantDetail 
    $AzureADCurrentSessionInfo = Get-AzureADCurrentSessionInfo
    if ($UserPrincipalName -and ($AzureADCurrentSessionInfo.Account.Id) -ne $UserPrincipalName) {
        Write-Host ('Azure AD session exists, authenticated with another identity: ' + ($AzureADCurrentSessionInfo.Account.Id))
        $answer = Read-Host -Prompt "Do you want to switch to $UserPrincipalName? (Y/n)"
        if ($answer -notin @('n','N')) {
            Disconnect-AzureAD -Confirm:$false
            throw 'Reconnect'
        }
    }
} catch {
    $account = if ($UserPrincipalName) { $UserPrincipalName } else { $null }
    Write-Host ('Connecting to Azure AD with identity: ' + $account)
    Connect-AzureAD -AccountId $account | Out-Null
    try {
        $tenantDetail = Get-AzureADTenantDetail
        $AzureADCurrentSessionInfo = Get-AzureADCurrentSessionInfo
    } catch {
        Write-Error -Exception 'Could not connect'
        return
    }
    Write-Host ("Connected to Azure AD '{0}' (ID: {1})" -f $tenantDetail.DisplayName, $tenantDetail.ObjectId)
}

# Get Current Account ID
$CurrentAccountId = (Get-AzureADUser -ObjectId $AzureADCurrentSessionInfo.Account.Id).ObjectId

# Get Azure AD role Information.
Write-Host 'Get all privileged role definitions'
$AzureADMSPrivilegedRoleDefinitions = Get-AzureADMSPrivilegedRoleDefinition -ProviderId 'aadRoles' -ResourceId $AzureADCurrentSessionInfo.TenantId.Guid 

Write-Host 'Get all privileged role settings'
$AzureADMSPrivilegedRoleSettings = Get-AzureADMSPrivilegedRoleSetting -ProviderId 'aadRoles' -Filter "ResourceId eq '$($AzureADCurrentSessionInfo.TenantId)'"

Write-Host ("Get all privileged role assignments for " + ($AzureADCurrentSessionInfo.Account.Id))
$AzureADMSPrivilegedRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment -ProviderId 'aadRoles' -ResourceId $AzureADCurrentSessionInfo.TenantId -Filter "SubjectId eq '$CurrentAccountId'" 

# Exit if no roles are found that are assigned to the current user.
if ($AzureADMSPrivilegedRoleAssignments.Count -eq 0) {
    Write-Host ('No eligible PIM roles found to activate for: ' + $AzureADCurrentSessionInfo.Account.Id)
    return
}

# Create a custom object with the role object list
$SortedFiteredAzureADMSPrivilegedRoleAssignments = (($AzureADMSPrivilegedRoleAssignments | Group-Object RoleDefinitionId) | ForEach-Object { $_.Group | Sort-Object AssignmentState,Id | Select-Object -First 1 })
Write-Host 'Adding roles to the role selection list.'

$CurrentAccountRoles = @()
foreach ($RoleAssignment in $SortedFiteredAzureADMSPrivilegedRoleAssignments) {
    $roleDisplayName = ($AzureADMSPrivilegedRoleDefinitions | Where-Object { $_.Id -eq $RoleAssignment.RoleDefinitionId }).DisplayName
    $CustomObject = [pscustomobject]@{
        RoleDefinitionId            = $RoleAssignment.RoleDefinitionId
        DisplayName                 = $roleDisplayName
        AssignmentState             = if ($RoleAssignment.AssignmentState -eq 'Active' -and -not $RoleAssignment.EndDateTime) { 'Permanent' } else { $RoleAssignment.AssignmentState }
        maximumGrantPeriodInMinutes = (((($AzureADMSPrivilegedRoleSettings | Where-Object { $_.RoleDefinitionId -eq $RoleAssignment.RoleDefinitionId }).UserMemberSettings) | Where-Object { $_.RuleIdentifier -eq 'ExpirationRule' }).Setting | ConvertFrom-Json).maximumGrantPeriodInMinutes
        EndDateTime                 = if ($RoleAssignment.EndDateTime) { $RoleAssignment.EndDateTime.ToLocalTime() } else { $null }
    }
    if ($ShowAssignment) {
        $RoleAssignmentobject = Get-AzureADMSPrivilegedRoleAssignment -ProviderId 'aadRoles' -Id $RoleAssignment.Id -ResourceId $RoleAssignment.ResourceId
        $RoleAssignmentToIdentity = Get-AzureADObjectByObjectId -ObjectIds $RoleAssignmentobject.SubjectId
        $CustomObject | Add-Member -MemberType NoteProperty -Name 'RoleAssignmentId' -Value $RoleAssignmentobject.Id
        $CustomObject | Add-Member -MemberType NoteProperty -Name 'RoleAssignedTo' -Value $RoleAssignmentToIdentity.DisplayName
    }
    $CurrentAccountRoles += $CustomObject
}

if (-not $RoleNames) {
    $RolesToActivate = $CurrentAccountRoles | Sort-Object DisplayName | Out-GridView -Title ("Select roles to activate for " + ($AzureADCurrentSessionInfo.Account.Id)) -OutputMode Multiple
} else {
    $RolesToActivate = $CurrentAccountRoles | Where-Object { $_.DisplayName -in $RoleNames }
}

if ($RolesToActivate) {
    $Reason = 'Role activation'
    Write-Host ''
    Write-Host -ForegroundColor 'Yellow' 'PIM Role Activation'
    foreach ($Role in $RolesToActivate) {
        if ($Role.AssignmentState -ne 'Permanent') {
            if (($Role.AssignmentState -ne 'Active') -or $RefreshRoleActivation) {
                $Duration = ($Role.maximumGrantPeriodInMinutes / 60)
                # Create activation schedule based on the current role limit.
                $Schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                $Schedule.Type = 'Once'
                $Schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                $Schedule.EndDateTime = ((Get-Date).AddHours($Duration)).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                try {
                    Write-Host "Activating role '$($Role.DisplayName)'...  " -ForegroundColor DarkYellow -NoNewline
                    $activatedRole = Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $AzureADCurrentSessionInfo.TenantId -RoleDefinitionId $Role.RoleDefinitionId -SubjectId $CurrentAccountId -Type 'UserAdd' -AssignmentState 'Active' -Schedule $Schedule -Reason $Reason
                    Write-Host "$($Role.DisplayName) has been activated until $($Schedule.EndDateTime)" -ForegroundColor DarkYellow
                } catch {
                    Write-Host ("$($Role.DisplayName) has NOT been activated. Error: " + ($_.Exception.Message)) -ForegroundColor Red
                }
            } else {
                Write-Host ("$($Role.DisplayName) was already activated, to refresh use the switch -RefreshRoleActivation.") -ForegroundColor DarkYellow
            }
        } else {
            Write-Host "$($Role.DisplayName) not dynamically activated, assignment is permanent" -ForegroundColor DarkYellow
        }
    }
} else {
    Write-Host -ForegroundColor 'Yellow' 'No role selected to activate'
}
