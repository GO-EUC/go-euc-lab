[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Endpoint,
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][securestring]$Password,
    [Parameter(Mandatory = $true)][string]$StorageContainerUuid,
    [Parameter(Mandatory = $true)][string]$ImageName,
    [Parameter(Mandatory = $true)][string]$ImageSourceUri,
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [string]$AdapterPath = "scripts/nutanix/Invoke-PrismElement.ps1",
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = "Stop"
& $AdapterPath -ImageAction CreateImage -Endpoint $Endpoint -Username $Username -Password $Password `
    -Name $ImageName -ImageSourceUri $ImageSourceUri -StorageContainerUuid $StorageContainerUuid `
    -SkipCertificateCheck:$SkipCertificateCheck | Out-Null

$plainPassword = [Net.NetworkCredential]::new("", $Password).Password
$token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${plainPassword}"))
$parameters = @{
    Uri     = "https://$($Endpoint.TrimEnd('/')):9440/PrismGateway/services/rest/v2.0/images/"
    Headers = @{ Authorization = "Basic $token" }
}
if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 7) {
    $parameters.SkipCertificateCheck = $true
}
$image = (Invoke-RestMethod @parameters).entities | Where-Object { $_.name -eq $ImageName } | Select-Object -First 1
if (!$image -or [string]::IsNullOrWhiteSpace($image.vm_disk_id)) {
    throw "Prism did not return a cloneable vm_disk_id for image '$ImageName'."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $ManifestPath) -Force | Out-Null
@{
    builds = @(@{
        name        = $ImageName
        builder_type = "prism-element-direct"
        artifact_id = $image.vm_disk_id
    })
} | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestPath -Encoding utf8
