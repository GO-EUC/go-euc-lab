<#
.SYNOPSIS
    Writes a normalized manifest for a Nutanix image so Terraform can clone it.

.DESCRIPTION
    Prism Element clones VM disks from an image's vm_disk_id, not the image
    UUID. This script resolves an image by name through the Prism Element v2
    API and writes a Packer-style manifest with that disk id as artifact_id.

    The image normally already exists because the Nutanix image pipeline
    builds it with the Packer Nutanix (Prism Central) builder. When the image
    is missing and -ImageSourceUri is provided, the image is imported through
    the Prism Element adapter first (the original import-based flow).

.EXAMPLE
    ./New-PrismImageManifest.ps1 -Endpoint 10.0.0.20 -Username admin -Password $secure `
        -ImageName windows-server-2022-standard `
        -ManifestPath manifests/windows-server-2022-standard.json -SkipCertificateCheck
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Endpoint,
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][securestring]$Password,
    [Parameter(Mandatory = $true)][string]$ImageName,
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [string]$ImageSourceUri,
    [string]$StorageContainerUuid,
    [string]$AdapterPath = "scripts/nutanix/Invoke-PrismElement.ps1",
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = "Stop"

function Get-PrismImage {
    $plainPassword = [Net.NetworkCredential]::new("", $Password).Password
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${plainPassword}"))
    $parameters = @{
        Uri     = "https://$($Endpoint.TrimEnd('/')):9440/PrismGateway/services/rest/v2.0/images/"
        Headers = @{ Authorization = "Basic $token" }
    }
    if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 7) {
        $parameters.SkipCertificateCheck = $true
    }
    (Invoke-RestMethod @parameters).entities | Where-Object { $_.name -eq $ImageName } | Select-Object -First 1
}

$image = Get-PrismImage
if (!$image -and -not [string]::IsNullOrWhiteSpace($ImageSourceUri)) {
    if ([string]::IsNullOrWhiteSpace($StorageContainerUuid)) {
        throw "Importing '$ImageName' from a URI requires -StorageContainerUuid."
    }
    & $AdapterPath -ImageAction CreateImage -Endpoint $Endpoint -Username $Username -Password $Password `
        -Name $ImageName -ImageSourceUri $ImageSourceUri -StorageContainerUuid $StorageContainerUuid `
        -SkipCertificateCheck:$SkipCertificateCheck | Out-Null
    $image = Get-PrismImage
}

if (!$image) {
    throw "Image '$ImageName' does not exist in the Prism image library. Run the Nutanix image pipeline first."
}
if ([string]::IsNullOrWhiteSpace($image.vm_disk_id)) {
    throw "Prism did not return a cloneable vm_disk_id for image '$ImageName'."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $ManifestPath) -Force | Out-Null
@{
    builds = @(@{
        name         = $ImageName
        builder_type = "prism-element-direct"
        artifact_id  = $image.vm_disk_id
    })
} | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestPath -Encoding utf8
Write-Host "Manifest for image '$ImageName' written to '$ManifestPath' (vm_disk_id: $($image.vm_disk_id))."
