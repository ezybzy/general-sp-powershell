asnp Microsoft.SharePoint.PowerShell

$siteCollection = "http://sitecollecionurl"
# Add more properties to mapped here!
$mappedProperties = "SPS-SIPAddress", "WorkEmail"

Start-SPAssignment -Global

# Array
$domainaUsers = @()
# Hash
$domainbUsers = @{}

$servicecontext = Get-SPServiceContext $siteCollection
$profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($servicecontext)

$profiles = $profileManager.GetEnumerator()
while ($profiles.MoveNext()) {
    $userprofile = $profiles.Current;

    if ($userprofile.AccountName -match "^domaina\\") {

        $domainbAccountName = "domainb\$($userprofile.AccountName.Split('\')[1])"

        try {
            $domainbUser = $profileManager.GetUserProfile($domainbAccountName)
            $domainbUsers.Add($userprofile.AccountName, $domainbUser)
            $domainaUsers += $userprofile
        } catch {
            #Write-Error "No domaina $($userprofile.AccountName) in domainb $domainbAccountName"
        }
    }
}

## For testing purpose (make sure to use accname that exist on both domains)
#$accname = "xxx"
#$acc = $profileManager.GetUserProfile('domaina\$($accname)')
#$domainaUsers += $acc
#$domainbUsers.Add($acc.AccountName, $profileManager.GetUserProfile('domainb\$($accname)'))

$domainaUsers | % {
    $u = $_
    $ug = $domainbUsers[$u.AccountName]

    $mappedProperties | % {
        $p = $_
        $u[$p].Value = $ug[$p].Value
    }

    $u.Commit()
    "Copy properties $($mappedProperties) from $($ug.AccountName) to $($u.AccountName). Done!" | Out-Default
}

$domainaUsers.Clear()
$domainbUsers.Clear()

Stop-SPAssignment -Global
