param (
    [Parameter()]
    [string]
    $StateFile,

    [Parameter()]
    [string]
    $InventoryFile
)

$state = Get-Content -Path $StateFile -Raw | ConvertFrom-Json

$machines = $state.outputs.PSObject.Properties | Select-Object Name

$content = @()
foreach ($machine in $machines) {
    $content += "[$($machine.Name)]"

    $machineProperties = $state.outputs.$($machine.Name).Value

    foreach ($machineProperty in $machineProperties) {
        $content += $machineProperty
    }

    $content += ""
}

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