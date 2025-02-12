#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2

$params = Parse-Args $args -supports_check_mode $false

$debug_level = Get-AnsibleParam -obj $params -name "_ansible_verbosity" -type "int"
$debug = $debug_level -gt 2

$state = Get-AnsibleParam $params "state" -type "str" -Default "present"

$result = @{
    changed = $false
}
$pathTest = Test-Path -Path "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty"
if ($state -eq "present") {

  $Version = (((Invoke-WebRequest "https://api.github.com/repos/0x6d69636b/windows_hardening/releases/latest" -UseBasicParsing) | ConvertFrom-Json).Name).SubString(2)
  $install = $true
  if ($pathTest -eq $true) {
    $localVersion = (Get-ChildItem -Path "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty\").Name
    if ($localVersion -eq $Version) {
      $install = $false
    }
  }
  if ($install) {

    $HardeningKittyLatestVersionDownloadLink = ((Invoke-WebRequest "https://api.github.com/repos/0x6d69636b/windows_hardening/releases/latest" -UseBasicParsing) | ConvertFrom-Json).zipball_url
    $ProgressPreference = 'SilentlyContinue'

    Invoke-WebRequest $HardeningKittyLatestVersionDownloadLink -Out "$($env:TEMP)\HardeningKitty$Version.zip"
    Expand-Archive -Path "$($env:TEMP)\HardeningKitty$Version.zip" -Destination "$($env:TEMP)\HardeningKitty$Version" -Force

    $Folder = Get-ChildItem "$($env:TEMP)\HardeningKitty$Version" | Select-Object Name -ExpandProperty Name
    Move-Item "$($env:TEMP)\HardeningKitty$Version\$Folder\*" "$($env:TEMP)\HardeningKitty$Version\"
    Remove-Item "$($env:TEMP)\HardeningKitty$Version\$Folder\"

    New-Item -Path "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty\$Version" -ItemType Directory

    Copy-Item -Path "$($env:TEMP)\HardeningKitty$Version\HardeningKitty.psd1","$($env:TEMP)\HardeningKitty$Version\HardeningKitty.psm1","$($env:TEMP)\HardeningKitty$Version\lists\" -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty\$Version\" -Recurse
    # Import-Module "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty\$Version\HardeningKitty.psm1"

    Remove-Item "$($env:TEMP)\HardeningKitty$Version" -Recurse -Force
    Remove-Item "$($env:TEMP)\HardeningKitty$Version.zip"

    $result.changed = $true
  }
} elseif ($state -eq "absent") {
  if ($pathTest -eq $true) {
    Remove-Item "$($env:ProgramFiles)\WindowsPowerShell\Modules\HardeningKitty" -Recurse -Force
    $result.changed = $true
  }
}

Exit-Json $result