[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Endpoint,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [securestring]$Password,

    [string]$OutputPath = "prism-element-capabilities.json",

    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = "Stop"

function Invoke-PrismElementRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet("Get", "Post", "Put", "Delete")][string]$Method = "Get",
        [object]$Body
    )

    $plainPassword = [System.Net.NetworkCredential]::new("", $Password).Password
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${plainPassword}"))
    $headers = @{ Authorization = "Basic $token"; Accept = "application/json" }
    $parameters = @{
        Uri         = "https://$($Endpoint.TrimEnd('/')):9440$Path"
        Method      = $Method
        Headers     = $headers
        ContentType = "application/json"
    }

    if ($PSBoundParameters.ContainsKey("Body")) {
        $parameters.Body = $Body | ConvertTo-Json -Depth 20 -Compress
    }

    if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 7) {
        $parameters.SkipCertificateCheck = $true
    }

    Invoke-RestMethod @parameters
}

function Test-PrismEndpoint {
    param([string]$Path)

    try {
        $response = Invoke-PrismElementRequest -Path $Path
        return @{ supported = $true; error = $null; response = $response }
    } catch {
        return @{ supported = $false; error = $_.Exception.Message; response = $null }
    }
}

$cluster = Test-PrismEndpoint -Path "/PrismGateway/services/rest/v2.0/clusters/"
$storage = Test-PrismEndpoint -Path "/PrismGateway/services/rest/v2.0/storage_containers/"
$networks = Test-PrismEndpoint -Path "/PrismGateway/services/rest/v2.0/networks/"
$images = Test-PrismEndpoint -Path "/PrismGateway/services/rest/v2.0/images/"
$vms = Test-PrismEndpoint -Path "/PrismGateway/services/rest/v2.0/vms/"

$result = [ordered]@{
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    endpoint     = $Endpoint
    authentication = "basic"
    api = [ordered]@{
        cluster            = $cluster.supported
        storage_containers = $storage.supported
        networks           = $networks.supported
        images             = $images.supported
        virtual_machines   = $vms.supported
        task_polling       = $vms.supported
    }
    cluster = if ($cluster.supported) { $cluster.response.entities | Select-Object -First 1 -Property name, uuid, version } else { $null }
    storage_containers = if ($storage.supported) { @($storage.response.entities | ForEach-Object { [ordered]@{ name = $_.name; uuid = $_.storage_container_uuid } }) } else { @() }
    networks = if ($networks.supported) { @($networks.response.entities | ForEach-Object { [ordered]@{ name = $_.name; uuid = $_.uuid; vlan_id = $_.vlan_id } }) } else { @() }
    limitations = @(
        "This probe is read-only and does not create test images or VMs.",
        "Guest customization and create/delete support must be verified by the deployment adapter on the target CE release.",
        "Prism Element uses username/password authentication; Prism Central is not required by this track."
    )
    errors = [ordered]@{
        cluster            = $cluster.error
        storage_containers = $storage.error
        networks           = $networks.error
        images             = $images.error
        virtual_machines   = $vms.error
    }
}

$result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding utf8
$result
