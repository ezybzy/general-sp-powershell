<#
.SYNOPSIS
    Enables and configures the SharePoint BLOB Cache. 
 
.DESCRIPTION
    Enables and configures the SharePoint BLOB Cache. 
 
.NOTES
    File Name: Enable-BlobCache.ps1
    Author   : Disorn Homchuenchom
    Version  : 3.0
 
.PARAMETER Url
    Specifies the URL of the Web Application for which the BLOB cache should be enabled. 
 
.PARAMETER Location
    Specifies the location of the BLOB Cache. 	 
 
.EXAMPLE
    PS > .\Enable-BlobCache.ps1 -Url http://intranet.westeros.local -Location d:\BlobCache\Intranet
 
   Description
   -----------
   This script enables the BLOB cache for the http://intranet.westeros.local web application and stores
   it under d:\blobcache\intranet
#>
param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
    [string]$Url,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)]
    [ValidateScript({
        ((Test-Path $_) -and -not $Disable) -or $Disable
    })]
    [string]$Location,
    [int]$MaxAge = 86400,
    [switch]$Disable
)

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$ownerId = "BlobCacheMod"
 
$webApp = Get-SPWebApplication $Url
$modifications = $webApp.WebConfigModifications | ? { $_.Owner -eq $ownerId }
if ($modifications.Count -ne $null -and $modifications.Count -gt 0)
{
    Write-Host -ForegroundColor Yellow "Modifications have already been added!"

    if ($Disable)
    {
        $modifications | % {
            $webApp.WebConfigModifications.Remove($_) | Out-Null
        }
        $webApp.Update()
        $webApp.Parent.ApplyWebConfigModifications()

        Write-Host -ForegroundColor Yellow "Modifications have been removed!"
    }
 
    break
}
elseif ($Disable)
{
    Write-Error "No modifications have been removed."
    break
}

# Enable Blob cache
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config1.Path = "configuration/SharePoint/BlobCache" 
$config1.Name = "enabled"
$config1.Value = "true"
$config1.Sequence = 0
$config1.Owner = $ownerId 
$config1.Type = [Microsoft.SharePoint.Administration.SPWebConfigModification+SPWebConfigModificationType]::EnsureAttribute
 
# add max-age attribute
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config2.Path = "configuration/SharePoint/BlobCache" 
$config2.Name = "max-age"
$config2.Value = $MaxAge
$config2.Sequence = 0
$config2.Owner = $ownerId
$config2.Type = [Microsoft.SharePoint.Administration.SPWebConfigModification+SPWebConfigModificationType]::EnsureAttribute 
 
# Set the location
[Microsoft.SharePoint.Administration.SPWebConfigModification] $config3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
$config3.Path = "configuration/SharePoint/BlobCache" 
$config3.Name = "location"
$config3.Value = $Location
$config3.Sequence = 0
$config3.Owner = $ownerId 
$config3.Type = [Microsoft.SharePoint.Administration.SPWebConfigModification+SPWebConfigModificationType]::EnsureAttribute
 
#Add mods to webapp and apply to web.config
$webApp.WebConfigModifications.Add($config1)
$webApp.WebConfigModifications.Add($config2)
$webApp.WebConfigModifications.Add($config3)
$webApp.Update()
$webApp.Parent.ApplyWebConfigModifications()
