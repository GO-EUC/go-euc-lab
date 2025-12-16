#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2


$params = Parse-Args $args -supports_check_mode $false

$debug_level = Get-AnsibleParam -obj $params -name "_ansible_verbosity" -type "int"
$debug = $debug_level -gt 2

$gateway = Get-AnsibleParam $params "gateway" -type "str" -FailIfEmpty $true
$username = Get-AnsibleParam $params "username" -type "str" -FailIfEmpty $true
$password = Get-AnsibleParam $params "password" -type "str" -FailIfEmpty $true

$provider_type = Get-AnsibleParam $params "provider_type" -type "str" -Default "VCenter"
$provider_server = Get-AnsibleParam $params "provider_server" -type "str" -FailIfEmpty $true
$provider_username = Get-AnsibleParam $params "provider_username" -type "str" -FailIfEmpty $true
$provider_password = Get-AnsibleParam $params "provider_password" -type "str" -FailIfEmpty $true
$provider_version = Get-AnsibleParam $params "provider_version" -type "str" -Default "v8_0"

$state = Get-AnsibleParam $params "state" -type "str" -Default "present"

$result = @{
    changed = $false
}

try {
  Import-Module -Name 'RASAdmin'
} catch{
  Fail-Json $result "Failed to import the required PowerShell module. Error: $($_)"
}

if ($state -eq "absent") {
  try {
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    New-RASSession -Username $username -Password $securePassword
  } catch {
    Fail-Json $result "Fail to setup new RAS Session. Error: $($_)"
  }

  ## Remove Gateway if exists
  try {
    $listGateway = Get-RASGateway

    $filterGateway = $listGateway | Where-Object { $_.Server -eq $gateway }

    if ($filterGateway) {
      $filterGateway | Remove-RASGateway

      Invoke-RASApply
      $result.changed = $true
    }
  } catch {
    Fail-Json $result "Fail to create new RAS Gateway. Error: $($_)"
  }

  ## Remove Provider if exists
    ## Create Provider if not exists
  try {
    $listProvider = Get-RASProvider
    $filterProvider = $listProvider | Where-Object { $_.Server -eq $provider_server }

    if ($filterProvider) {
      $filterProvider | Remove-RASProvider

      Invoke-RASApply
      $result.changed = $true
    }
  } catch {
    Fail-Json $result "Fail to create new RAS Gateway. Error: $($_)"
  }

} else {
  try {
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    New-RASSession -Username $username -Password $securePassword
  } catch {
    Fail-Json $result "Fail to setup new RAS Session. Error: $($_)"
  }

  ## Create Gateway if not exists
  try {
    $listGateway = Get-RASGateway

    $filterGateway = $listGateway | Where-Object { $_.Server -eq $gateway }

    if (!$filterGateway) {
      New-RASGateway -Server $gateway -NoRestart

      Invoke-RASApply
      $result.changed = $true
    }
  } catch {
    Fail-Json $result "Fail to create new RAS Gateway. Error: $($_)"
  }

  ## Create Provider if not exists
  try {
    $listProvider = Get-RASProvider
    $filterProvider = $listProvider | Where-Object { $_.Server -eq $provider_server }

    if (!$filterProvider) {

      $securePassword = ConvertTo-SecureString -String $provider_password -AsPlainText -Force
      New-RASProvider -Server $provider_server -VCenter -VCenterVersion $provider_version -NoRestart -ProviderUsername $provider_username -ProviderPassword $securePassword

      Invoke-RASApply
      $result.changed = $true
    }
  } catch {
    Fail-Json $result "Fail to create new RAS Gateway. Error: $($_)"
  }

}

Exit-Json $result