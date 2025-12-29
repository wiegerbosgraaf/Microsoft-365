# Script – Enable online archive and auto-expanding archive for a mailbox when the archive reaches its maximum size

# Connect to Exchange Online (interactive login required)
Connect-ExchangeOnline

# Specify the mailbox identity (UserPrincipalName or alias)
$Identity = "<user@example.com>"

# View current mailbox and archive storage statistics
Get-MailboxStatistics -Identity $Identity | Format-List StorageLimitStatus,TotalItemSize,TotalDeletedItemSize,ItemCount,DeletedItemCount
Get-MailboxStatistics -Identity $Identity -Archive | Format-List DisplayName,StorageLimitStatus,TotalItemSize,TotalDeletedItemSize,ItemCount,DeletedItemCount

# Enable the archive for the mailbox (if not already enabled)
Enable-Mailbox -Identity $Identity -Archive

# Run the Managed Folder Assistant to expedite cleanup and then enable auto-expanding archive
# These commands may take a few minutes to succeed after enabling the archive.
Start-ManagedFolderAssistant -Identity $Identity -HoldCleanup
Enable-Mailbox -Identity $Identity -AutoExpandingArchive
