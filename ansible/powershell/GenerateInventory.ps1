param (
    [Parameter()]
    [string]
    $StateFile,

    [Parameter()]
    [string]
    $InventoryFile  
)

$state = Get-Content -Path $StateFile -Raw | ConvertFrom-Json

$machines = $state.outputs.PSObject.Properties | Where-Object {$_.Name -ne "admin" -and $_.Name -ne "vault" -and $_.Name -ne "vault_resource_group" } | Select-Object Name

$content = @()
foreach ($machine in $machines) {
    $content += "[$($machine.Name)]"

    $machineProperties = $state.outputs.$($machine.Name).Value

    foreach ($machineProperty in $machineProperties) {
        $content += $machineProperty
    }

    $content += ""
}

$content += "[all:vars]"
$content += "vault_name=$($state.outputs.vault.value)"
$content += "resource_group=$($state.outputs.vault_resource_group.value)"
$content += "ansible_user=$($state.outputs.admin.value)"
$content += "reverse_dns_zone=$($state.outputs.reverse_dns_zone.value)"

$inventoryDir = $InventoryFile.Substring(0,$InventoryFile.LastIndexOf("/"))
if ($inventoryDir -ne ".") {
    
    if ((Test-Path -Path $inventoryDir) -eq $false) {
        try {
            New-Item -Path $inventoryDir -ItemType Directory -Force | Out-Null
        } catch {
            throw "Error while creating directory: $($_.Exception.Message)"
        }
    }
}

Set-Content -Path $InventoryFile -Value $content