# Script – Export all room lists and associated rooms

# Configuration
$OutputPath = "C:\Exports\RoomLists_Full_Export.csv"

# Ensure the output directory exists
$Folder = Split-Path $OutputPath
if (-not (Test-Path $Folder)) {
    New-Item -Path $Folder -ItemType Directory | Out-Null
}

# Retrieve room lists
$RoomLists = Get-DistributionGroup -RecipientTypeDetails RoomList

$Results = foreach ($RoomList in $RoomLists) {
    $Members = Get-DistributionGroupMember -Identity $RoomList.Identity -ResultSize Unlimited |
        Where-Object { $_.RecipientTypeDetails -eq "RoomMailbox" }

    if (-not $Members) {
        # Include empty room list
        [PSCustomObject]@{
            RoomListName          = $RoomList.Name
            RoomListEmail         = $RoomList.PrimarySmtpAddress
            RoomListHiddenFromGAL = $RoomList.HiddenFromAddressListsEnabled

            RoomName          = $null
            RoomEmail         = $null
            RoomHiddenFromGAL = $null

            City      = $null
            Building  = $null
            Floor     = $null
            Capacity  = $null
        }
        continue
    }

    foreach ($Member in $Members) {
        $Mailbox = Get-Mailbox -Identity $Member.PrimarySmtpAddress
        $Place   = Get-Place -Identity $Member.PrimarySmtpAddress -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            # Room list properties
            RoomListName          = $RoomList.Name
            RoomListEmail         = $RoomList.PrimarySmtpAddress
            RoomListHiddenFromGAL = $RoomList.HiddenFromAddressListsEnabled

            # Room properties
            RoomName          = $Mailbox.DisplayName
            RoomEmail         = $Mailbox.PrimarySmtpAddress
            RoomHiddenFromGAL = $Mailbox.HiddenFromAddressListsEnabled

            # Places metadata
            City      = $Place.City
            Building  = $Place.Building
            Floor     = $Place.Floor
            Capacity  = $Place.Capacity
        }
    }
}

# Export results to CSV
$Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete:"
Write-Host $OutputPath
