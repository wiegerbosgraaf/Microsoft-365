<#
.SYNOPSIS
    Cleans up legacy Room Lists by removing rooms that are now included in target Room Lists.
.DESCRIPTION
    This script builds a membership map of all room mailboxes in your tenant and their associated room lists. It then iterates through a set of legacy room lists and removes any room mailbox that is also a member of a target room list. A CSV log is generated with details of all actions performed. Use the $DryRun flag to preview changes without modifying room lists.
#>

# ------------- Configuration -------------
# Specify the display names of the target room lists (rooms anchored in these lists will be kept)
$TargetRoomLists = @(
    "Building A RoomList",  # Example list 1
    "Building B RoomList"   # Example list 2
)

# Specify the display names of legacy room lists to clean up
$LegacyRoomLists = @(
    "Floor1_Legacy", "Floor2_Legacy", "Conference_Legacy",
    "SmallRooms_Legacy", "MediumRooms_Legacy", "LargeRooms_Legacy",
    "Test_Rooms"
)

# Set DryRun to $true to preview actions without actually removing members
$DryRun  = $true

# Path to write the log CSV file
$LogPath = "C:\\Exports\\RoomList_Cleanup_Log.csv"

# ------------- Helper: ensure log folder exists -------------
$logFolder = Split-Path $LogPath
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
}

# ------------- 1) Build membership map: RoomEmail -> array of RoomList names -------------
Write-Host "Building RoomList membership map..."

$AllRoomLists = Get-DistributionGroup -RecipientTypeDetails RoomList -ResultSize Unlimited |
    Select-Object Name, PrimarySmtpAddress, Identity

$MembershipMap = @{}

foreach ($rl in $AllRoomLists) {
    $members = Get-DistributionGroupMember -Identity $rl.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue |
        Where-Object { $_.RecipientTypeDetails -eq "RoomMailbox" }

    foreach ($m in $members) {
        $key = ($m.PrimarySmtpAddress.ToString()).ToLower()

        if (-not $MembershipMap.ContainsKey($key)) {
            $MembershipMap[$key] = New-Object System.Collections.Generic.List[string]
        }

        if (-not $MembershipMap[$key].Contains($rl.Name)) {
            [void]$MembershipMap[$key].Add($rl.Name)
        }
    }
}

Write-Host ("Membership map built for {0} room mailboxes." -f $MembershipMap.Keys.Count)

# ------------- 2) Ensure target RoomLists exist -------------
foreach ($t in $TargetRoomLists) {
    if (-not (Get-DistributionGroup -Identity $t -ErrorAction SilentlyContinue)) {
        throw "Target RoomList not found: $t"
    }
}

# ------------- 3) Cleanup legacy lists safely -------------
$Log = New-Object System.Collections.Generic.List[object]

foreach ($legacyName in $LegacyRoomLists) {

    $legacyDG = Get-DistributionGroup -Identity $legacyName -ErrorAction SilentlyContinue
    if (-not $legacyDG) {
        $Log.Add([PSCustomObject]@{
            Timestamp      = (Get-Date).ToString("s")
            Action         = "SkipLegacyList"
            LegacyRoomList = $legacyName
            RoomEmail      = $null
            Reason         = "Legacy RoomList not found"
            DryRun         = $DryRun
        })
        continue
    }

    Write-Host "Processing legacy RoomList: $legacyName"

    $legacyMembers = Get-DistributionGroupMember -Identity $legacyDG.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue |
        Where-Object { $_.RecipientTypeDetails -eq "RoomMailbox" }

    foreach ($m in $legacyMembers) {

        $roomEmail = $m.PrimarySmtpAddress.ToString()
        $key       = $roomEmail.ToLower()

        $roomLists = @()
        if ($MembershipMap.ContainsKey($key)) {
            $roomLists = @($MembershipMap[$key])
        }

        # A room is anchored if it belongs to at least one target RoomList
        $anchored = $false
        foreach ($t in $TargetRoomLists) {
            if ($roomLists -contains $t) {
                $anchored = $true
                break
            }
        }

        if (-not $anchored) {
            # Skip removing rooms that are not anchored; just log the reason
            $Log.Add([PSCustomObject]@{
                Timestamp        = (Get-Date).ToString("s")
                Action           = "SkipMember"
                LegacyRoomList   = $legacyName
                RoomEmail        = $roomEmail
                Reason           = "Room not anchored in target RoomList(s)"
                CurrentRoomLists = ($roomLists -join ", ")
                DryRun           = $DryRun
            })
            continue
        }

        if ($DryRun) {
            # Log what would be removed
            $Log.Add([PSCustomObject]@{
                Timestamp        = (Get-Date).ToString("s")
                Action           = "WouldRemove"
                LegacyRoomList   = $legacyName
                RoomEmail        = $roomEmail
                Reason           = "Anchored in target RoomList(s)"
                CurrentRoomLists = ($roomLists -join ", ")
                DryRun           = $DryRun
            })
        }
        else {
            try {
                Remove-DistributionGroupMember -Identity $legacyDG.Identity -Member $roomEmail -Confirm:$false -ErrorAction Stop
                $Log.Add([PSCustomObject]@{
                    Timestamp        = (Get-Date).ToString("s")
                    Action           = "Removed"
                    LegacyRoomList   = $legacyName
                    RoomEmail        = $roomEmail
                    Reason           = "Anchored in target RoomList(s)"
                    CurrentRoomLists = ($roomLists -join ", ")
                    DryRun           = $DryRun
                })
            }
            catch {
                $Log.Add([PSCustomObject]@{
                    Timestamp        = (Get-Date).ToString("s")
                    Action           = "Error"
                    LegacyRoomList   = $legacyName
                    RoomEmail        = $roomEmail
                    Reason           = $_.Exception.Message
                    CurrentRoomLists = ($roomLists -join ", ")
                    DryRun           = $DryRun
                })
            }
        }
    }
}

# ------------- 4) Export log -------------
$Log | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Cleanup completed. Log written to:"
Write-Host $LogPath

if ($DryRun) {
    Write-Host ""
    Write-Host "DryRun = TRUE. No changes were made. Review the CSV, then set DryRun = `$false and rerun."
}
