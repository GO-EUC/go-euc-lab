<# 
  .SYNOPSIS
   This script will download the Citrix VDA version of choice. TThis script is forked from Ryan Butler. He is the original author of this script! 
   Original source: https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Get-BinaryExampleNEW.ps1

   GO-EUC Thans Ryan Butler for this script.

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
  [Parameter(Mandatory = $true)] [string]$MyCitrixPassword,
  [Parameter(Mandatory = $false)][string]$VDAVersion = "latest",
  [Parameter(Mandatory = $false)][ValidateSet('workstation','server')][string]$VDAType = "server"
)

function get-ctxbinary {
  <#
.SYNOPSIS
  Downloads a Citrix Binary or ISO from Citrix.com utilizing authentication
.DESCRIPTION
  Downloads a Citrix Bindary or ISO from Citrix.com utilizing authentication.
  Ryan Butler 2/10/2022
.PARAMETER DLobject
  Object for downloading the binary.
  Get from https://raw.githubusercontent.com/ryancbutler/Citrix_DL_Scrapper/main/ctx_dls.json
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
    [Parameter(Mandatory = $true)]$DLobject,
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
  $DLNUMBER = $DLobject.dlnumber
  $DLEXE = $DLobject.filename
  Write-Verbose $dlexe
  $dlurl = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=${DLNUMBER}&URL=https://downloads.citrix.com/${DLNUMBER}/${DLEXE}"
  Write-Verbose $DLURL
  $download = Invoke-WebRequest -Uri $dlurl -WebSession $websession -UseBasicParsing -Method GET
  $webform = @{ 
    "chkAccept"            = "on"
    "clbAccept"            = "Accept"
    "__VIEWSTATEGENERATOR" = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATEGENERATOR" }).value
    "__VIEWSTATE"          = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATE" }).value
    "__EVENTVALIDATION"    = ($download.InputFields | Where-Object { $_.id -eq "__EVENTVALIDATION" }).value
  }

  $outfile = ($DLPATH + $DLEXE)
  Write-Verbose $outfile
  #Download
  Invoke-WebRequest -Uri $dlurl -WebSession $websession -Method POST -Body $webform -ContentType "application/x-www-form-urlencoded" -UseBasicParsing -OutFile $outfile
  return $outfile
}
#End of Function

#Look up Citrix Download information from https://github.com/ryancbutler/Citrix_DL_Scrapper
$dls = invoke-restmethod "https://raw.githubusercontent.com/ryancbutler/Citrix_DL_Scrapper/main/ctx_dls.json"


switch ($VDAType) {
  "server"      {$product = "Multi-session OS Virtual Delivery Agent*"}
  "workstation" {$product = "Single-session OS Virtual Delivery Agent*"}
}

if ($VDAVersion -eq "latest") {
  #Get the latest VDA object from json data
  $vda = $dls | Where-Object { $_.family -eq "cvad" -and $_.product -like $product -and $_.version -notlike "7.*" } | Sort-Object version -Descending | Select-Object -first 1
} else {
  #Get a specific VDA object from json data
  $vda = $dls | Where-Object { $_.family -eq "cvad" -and $_.product -like $product -and $_.version -eq $VDAVersion }
}

Write-Verbose "Downloading version $($vda.version) of $($vda.filename)"

#Call above function to download binary
$file = get-ctxbinary -DLobj $vda -CitrixUserName $MyCitrixUsername -CitrixPassword $MyCitrixPassword -DLPATH "$($DownloadPath)\"

#CHECKSUM Check
$filehash = Get-FileHash $file -Algorithm SHA256

$hash = $vda.checksum.Split(" ")[-1]
If ($filehash.Hash -ne $hash) {
  throw "Checksum failed! for $file. Got $($filehash.Hash), expected $hash)"
}
else {
  Write-Verbose "Checksum passed!"
}

return $file