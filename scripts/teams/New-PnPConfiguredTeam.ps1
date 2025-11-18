# Script: New-PnPConfiguredTeam.ps1
# Description:
# This script creates a Microsoft Teams team with predefined settings using the PnP.PowerShell module.
# It checks whether the PnP.PowerShell module is installed and updates it if necessary.
# The script connects to your tenant's SharePoint admin endpoint with the provided ClientId and interactive login,
# then creates a new team with the specified display name, description, mail nickname, owners, members, sensitivity label,
# and various configuration settings. Modify the variables below before running.

# Variables (adjust these before running):
$DisplayName      = "Your Team Name"
$Description      = "Description of the team"
$MailNickName     = "TeamMailNickname"  # Do not use spaces in the MailNickname
$ClientID         = "<Your-Client-ID>"  # Application (client) ID registered in Azure AD for PnP.PowerShell
$TenantAdminUrl   = "https://<yourtenant>-admin.sharepoint.com/"
$Owners           = @("<owner1@domain.com>", "<owner2@domain.com>") # Array of owner UPNs
$Members          = @("<member1@domain.com>")                       # Array of member UPNs

# To determine the GUID for a sensitivity label (used in the $SensitivityLabel variable), connect to the Security & Compliance PowerShell module and run:
#   Connect-IPPSSession
#   Get-Label | Select-Object Name, ImmutableId
# This lists all sensitivity labels and their ImmutableId values (label GUIDs) in your tenant.
# Alternatively, to see the label assigned to an existing SharePoint site, connect to SharePoint Online and run:
#   Connect-SPOService -Url https://<tenant>-admin.sharepoint.com
#   Get-SPOSite -Identity "https://<tenant>.sharepoint.com/sites/YourSite" | Select-Object Url, SensitivityLabel
# The SensitivityLabel property contains the GUID of the label applied to the site. Use that GUID as the value for $SensitivityLabel below.

$SensitivityLabel = "<Sensitivity-Label-Guid>"  # Optional sensitivity label GUID

# Check if PnP.PowerShell module is installed and update if needed
$module = Get-InstalledModule -Name PnP.PowerShell -ErrorAction SilentlyContinue

if (-not $module) {
    Write-Host "PnP.PowerShell module is not installed. Installing the latest version..."
    Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force
} else {
    Write-Host "PnP.PowerShell is installed. Version: $($module.Version). Checking for updates..."
    $latest = Find-Module -Name PnP.PowerShell
    if ($latest.Version -gt $module.Version) {
        Write-Host "An update is available: $($latest.Version). Updating..."
        Update-Module -Name PnP.PowerShell -Force
        Write-Host "PnP.PowerShell has been updated to version $($latest.Version)."
    } else {
        Write-Host "PnP.PowerShell is up to date."
    }
}

# Connect to SharePoint admin using PnP (Interactive login required)
Connect-PnPOnline -Url $TenantAdminUrl -Interactive -ClientId $ClientID
Write-Host -ForegroundColor Yellow "Connected to tenant admin site: $TenantAdminUrl using client ID: $ClientID"

# Define team settings
$TeamSettings = @{
    AllowDeleteChannels             = $false
    AllowAddRemoveApps              = $false
    AllowChannelMentions            = $true
    AllowCreateUpdateConnectors     = $false
    AllowCustomMemes                = $false
    AllowGiphy                      = $false
    AllowStickersAndMemes           = $false
    AllowTeamMentions               = $true
    GiphyContentRating              = "Strict"  # Only Moderate or Strict
    AllowUserEditMessages           = $true
    AllowOwnerDeleteMessages        = $false
    AllowCreateUpdateChannels       = $false
    AllowCreateUpdateRemoveTabs     = $true
    AllowUserDeleteMessages         = $true
    AllowGuestCreateUpdateChannels  = $false
    AllowGuestDeleteChannels        = $false
    ShowInTeamsSearchAndSuggestions = $false
    Owners                          = $Owners
    Members                         = $Members
    ResourceBehaviorOptions         = "HideGroupInOutlook, WelcomeEmailDisabled"
    Visibility                      = "Private"
    SensitivityLabel                = $SensitivityLabel
    AllowCreatePrivateChannels      = $false
}

# Create the team
Write-Host -ForegroundColor Yellow "Creating team '$DisplayName'..."
$TeamObject = New-PnPTeamsTeam `
    -DisplayName $DisplayName `
    -Description $Description `
    -MailNickname $MailNickName `
    -AllowDeleteChannels $TeamSettings.AllowDeleteChannels `
    -AllowAddRemoveApps $TeamSettings.AllowAddRemoveApps `
    -AllowCreateUpdateChannels $TeamSettings.AllowCreateUpdateChannels `
    -AllowCreateUpdateRemoveTabs $TeamSettings.AllowCreateUpdateRemoveTabs `
    -AllowUserDeleteMessages $TeamSettings.AllowUserDeleteMessages `
    -AllowUserEditMessages $TeamSettings.AllowUserEditMessages `
    -AllowGuestCreateUpdateChannels $TeamSettings.AllowGuestCreateUpdateChannels `
    -AllowGuestDeleteChannels $TeamSettings.AllowGuestDeleteChannels `
    -Visibility $TeamSettings.Visibility `
    -SensitivityLabel $TeamSettings.SensitivityLabel `
    -ShowInTeamsSearchAndSuggestions $TeamSettings.ShowInTeamsSearchAndSuggestions `
    -Owners $TeamSettings.Owners `
    -Members $TeamSettings.Members `
    -ResourceBehaviorOptions $TeamSettings.ResourceBehaviorOptions `
    -AllowCreatePrivateChannels $TeamSettings.AllowCreatePrivateChannels `
    -Verbose

# Example: create additional channels (optional)
<# 
# Uncomment and customize the following block to create channels
$ProjectTeamChannels = @(
    @{
        DisplayName = "Channel1"
        Description = "Second channel for the team"
        ChannelType = "Standard"
    },
    @{
        DisplayName = "Private channel"
        Description = "Private collaboration space"
        ChannelType = "Private"
    }
)

foreach ($Channel in $ProjectTeamChannels) {
    if ($Channel.ChannelType -eq "Private") {
        foreach ($Owner in $Owners) {
            Add-PnPTeamsChannel -Team $TeamObject.GroupId `
                                -DisplayName $Channel.DisplayName `
                                -Description $Channel.Description `
                                -ChannelType $Channel.ChannelType `
                                -OwnerUPN $Owner
            Write-Host "Adding owner $Owner to private channel '$($Channel.DisplayName)'."
        }
    } else {
        Add-PnPTeamsChannel -Team $TeamObject.GroupId `
                            -DisplayName $Channel.DisplayName `
                            -Description $Channel.Description `
                            -ChannelType $Channel.ChannelType
    }
}
#>

# Disconnect session
Disconnect-PnPOnline

# End of script
