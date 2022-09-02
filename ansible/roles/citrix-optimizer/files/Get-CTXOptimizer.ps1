<# 
  .SYNOPSIS
   This script will download the Citrix Optimizer Tool. This script is forked from Ryan Butler. He is the original author of this script! 
   Original source: https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Get-BinaryExampleNEW.ps1

   GO-EUC Thanks Ryan Butler for this script.

  .DESCRIPTION
   Forked and edited the file from Ryan Butler. So we can download a specific VDA version for our GO-EUC LAB.

  .PARAMETER DownloadPath
   Path where the VDA is downloaded

  .PARAMETER MyCitrixUsername
   My Citrix Username with access to the VDA resources
  
  .PARAMETER MyCitrixPassword
   My Citrix Password with access to the VDA resources

  .PARAMETER CitrixEULAAccept
   True or false. By specifying True you confirm to all the EULA boxes in the GUI proces of downloading the VDA
  
  .PARAMETER VDAVersion
    Defaults to latest. But you can specify different version like 2106, 2112, etc.

  .PARAMETER VDAType
   Defaults to server. Options: "workstation" or "server"

  .EXAMPLE
   .\Get-CTXBinary.ps1 -MyCitrixUsername "usernameplain" -MyCitrixPassword "passwordplain" -DownloadPath "D:\Temp" -VDAVersion "2112" -VDAType "server" -CitrixEULAAccept $true

#>
[cmdletbinding()]
Param(
  [Parameter(Mandatory = $false)][string]$DownloadPath = "C:\InstallSources",
  [Parameter(Mandatory = $true)] [string]$MyCitrixUsername,
  [Parameter(Mandatory = $true)] [string]$MyCitrixPassword
)

function get-ctxbinary {
  <#
.SYNOPSIS
  Downloads a Citrix Binary or ISO from Citrix.com utilizing authentication
.DESCRIPTION
  Downloads a Citrix Bindary or ISO from Citrix.com utilizing authentication.
  Ryan Butler 2/10/2022
.PARAMETER DLEXE
  File to be downloaded
.PARAMETER DLPATH
  Path to store downloaded file. Must contain following slash (c:\temp\)
.PARAMETER CitrixUserName
  Citrix.com username
.PARAMETER CitrixPassword
  Citrix.com password
.EXAMPLE
  Get-CTXBinaryUpdated -DLobject $vda -CitrixUserName "mycitrixusername" -CitrixPassword "mycitrixpassword" -DLPATH "C:\temp\"
#>
  [cmdletbinding()]
  Param(
    [Parameter(Mandatory = $true)]$DLPATH,
    [Parameter(Mandatory = $true)]$CitrixUserName,
    [Parameter(Mandatory = $true)]$CitrixPassword
  )
  $ProgressPreference = 'SilentlyContinue'
  #Initialize Session 
  Invoke-WebRequest "https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response" -SessionVariable websession -UseBasicParsing | Out-Null

  #Set Form
  $form = @{
    "persistent" = "on"
    "userName"   = $CitrixUserName
    "password"   = $CitrixPassword
  }

  #Authenticate
  try {
    Invoke-WebRequest -Uri ("https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response") -WebSession $websession -Method POST -Body $form -ContentType "application/x-www-form-urlencoded" -UseBasicParsing -ErrorAction Stop | Out-Null
  }
  catch {
    if ($_.Exception.Response.StatusCode.Value__ -eq 500) {
      Write-Verbose "500 returned on auth. Ignoring"
      Write-Verbose $_.Exception.Response
      Write-Verbose $_.Exception.Message
    }
    else {
      throw $_
    }

  }

  $dlurl = "https://fileservice.citrix.com/download/secured/support/article/CTX224676/downloads/CitrixOptimizerTool.zip"
  Write-Verbose $DLURL

  $outfile = ($DLPATH + "CitrixOptimizerTool.zip")
  Write-Verbose $outfile

  #Download
  Invoke-WebRequest -Uri $dlurl -WebSession $websession -Method GET -UseBasicParsing -OutFile $outfile
  return $outfile
}
#End of Function


Write-Verbose "Downloading Citrix Optimizer Tool"

#Call above function to download binary
$file = get-ctxbinary -CitrixUserName $MyCitrixUsername -CitrixPassword $MyCitrixPassword -DLPATH "$($DownloadPath)\"

return $file