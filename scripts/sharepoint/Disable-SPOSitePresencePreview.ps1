# Script – Disable SharePoint Online presence preview
# This script disables the presence preview feature in the OneDrive and SharePoint file viewer for specified site collections.
#
# When users preview a file in OneDrive or SharePoint, they can see other users who have the file open. SharePoint admins can turn off this presence feature per site collection.
#
# Prerequisites:
# - Install the latest version of the SharePoint Online Management Shell.
# - You must be a SharePoint Online administrator.
#
# Instructions:
# 1. Connect to SharePoint Online using Connect-SPOService.
# 2. Specify the site URLs or IDs you want to update in the $SiteUrls array.
# 3. Run the script to set HidePeoplePreviewingFiles to $true for each site.
#
# Note: Disabling this feature may affect collaboration visibility. Revert by setting -HidePeoplePreviewingFiles $false.

# Connect to SharePoint Online (interactive login)
Connect-SPOService -Url "https://<tenant>-admin.sharepoint.com"

# List of site collection URLs to update
$SiteUrls = @(
    "https://<tenant>.sharepoint.com/sites/ExampleSite1",
    "https://<tenant>.sharepoint.com/sites/ExampleSite2"
)

foreach ($SiteUrl in $SiteUrls) {
    Write-Host "Disabling presence preview for $SiteUrl..." -ForegroundColor Yellow
    Set-SPOSite -Identity $SiteUrl -HidePeoplePreviewingFiles $true
    Write-Host "Presence preview disabled for $SiteUrl" -ForegroundColor Green
}

Write-Host "Completed updating presence settings for all specified sites." -ForegroundColor Cyan
