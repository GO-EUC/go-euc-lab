#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2


$params = Parse-Args $args -supports_check_mode $false

$debug_level = Get-AnsibleParam -obj $params -name "_ansible_verbosity" -type "int"
$debug = $debug_level -gt 2

$gateway = Get-AnsibleParam $params "gateway" -type "str" -FailIfEmpty $true
$username = Get-AnsibleParam $params "username" -type "str" -FailIfEmpty $true
$password = Get-AnsibleParam $params "password" -type "str" -FailIfEmpty $true
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
} else {
  try {
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    New-RASSession -Username $username -Password $securePassword
  } catch {
    Fail-Json $result "Fail to setup new RAS Session. Error: $($_)"
  }

  try {
    New-RASGateway -Server $gateway
    $result.changed = $true
  } catch {
    Fail-Json $result "Fail to create new RAS Gateway. Error: $($_)"
  }
}

Exit-Json $result