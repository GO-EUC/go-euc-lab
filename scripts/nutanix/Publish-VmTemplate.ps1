<#
.SYNOPSIS
    Publishes a powered-off AHV VM as a Prism Central VM template.

.DESCRIPTION
    Citrix Virtual Apps and Desktops 2603 MCS (Nutanix AHV Prism Central)
    selects a VM template version when creating or updating a machine catalog.
    This script powers off the delivery build VM and either creates that
    template or adds a new version from the current VM.

    Tries the VMM v4 template APIs first (pc.2024.3+). Falls back to the
    v3 vm_templates API used on older Prism Central builds.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PrismCentralEndpoint,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [securestring]$Password,

    [string]$PrismElementEndpoint,

    [securestring]$PrismElementPassword,

    [Parameter(Mandatory = $true)]
    [string]$VmName,

    [Parameter(Mandatory = $true)]
    [string]$TemplateName,

    [string]$VersionName = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss"),

    [string]$VersionDescription = "GO-EUC delivery master",

    [switch]$SkipCertificateCheck,

    [int]$TaskTimeoutSeconds = 1800
)

$ErrorActionPreference = "Stop"

function Get-BasicHeaders {
    param([securestring]$Secret)

    $plain = [Net.NetworkCredential]::new("", $Secret).Password
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${plain}"))
    @{
        Authorization    = "Basic $token"
        Accept           = "application/json"
        "Content-Type"   = "application/json"
        "NTNX-Request-Id" = [guid]::NewGuid().ToString()
    }
}

function Invoke-NutanixApi {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet("Get", "Post", "Put", "Delete")][string]$Method = "Get",
        [object]$Body,
        [securestring]$Secret,
        [int]$TimeoutSec = 120
    )

    $parameters = @{
        Uri         = "$($Base.TrimEnd('/'))$Path"
        Method      = $Method
        Headers     = Get-BasicHeaders -Secret $Secret
        TimeoutSec  = $TimeoutSec
    }
    if ($PSBoundParameters.ContainsKey("Body")) {
        $parameters.ContentType = "application/json"
        $parameters.Body = $Body | ConvertTo-Json -Depth 20 -Compress
    }
    if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 7) {
        $parameters.SkipCertificateCheck = $true
    }
    Invoke-RestMethod @parameters
}

function Get-NutanixStatusCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)

    $response = $ErrorRecord.Exception.Response
    if ($response -and $response.StatusCode) {
        return [int]$response.StatusCode
    }
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message -match '"code"\s*:\s*(\d+)') {
        return [int]$Matches[1]
    }
    return 0
}

function Wait-PrismTask {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$TaskUuid,
        [Parameter(Mandatory = $true)][securestring]$Secret
    )

    $deadline = (Get-Date).AddSeconds($TaskTimeoutSeconds)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Waiting for Prism task $TaskUuid."
    do {
        $task = $null
        try {
            $task = Invoke-NutanixApi -Base $Base -Path "/api/nutanix/v3/tasks/$TaskUuid" -Secret $Secret
        } catch {
            try {
                $v4 = Invoke-NutanixApi -Base $Base -Path "/api/prism/v4.0/config/tasks/$TaskUuid" -Secret $Secret
                $task = [pscustomobject]@{
                    status = $v4.data.status
                    error_detail = ($v4.data.errorMessages | ConvertTo-Json -Compress)
                }
            } catch {
                throw
            }
        }
        $status = [string]$task.status
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Task $TaskUuid status: $status."
        if ($status -in @("FAILED", "ABORTED", "CANCELED", "CANCELLED")) {
            throw "Prism task $TaskUuid ended with $status. $($task.error_detail)"
        }
        if ($status -in @("SUCCEEDED", "SUCCESS", "COMPLETED")) {
            return $task
        }
        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for Prism task $TaskUuid."
}

function Get-TaskUuidFromResponse {
    param([object]$Response)

    foreach ($candidate in @(
        $Response.status.execution_context.task_uuid,
        $Response.task_uuid,
        $Response.data.extId,
        $Response.metadata.uuid
    )) {
        if ($candidate) { return [string]$candidate }
    }
    return $null
}

function Find-PrismCentralVm {
    param([string]$Base, [securestring]$Secret, [string]$Name)

    $list = Invoke-NutanixApi -Base $Base -Path "/api/nutanix/v3/vms/list" -Method Post -Secret $Secret -Body @{
        kind   = "vm"
        filter = "vm_name==$Name"
        length = 50
    }
    $match = @($list.entities) | Where-Object { $_.spec.name -eq $Name } | Select-Object -First 1
    if (-not $match) {
        throw "Prism Central has no VM named '$Name'."
    }
    return $match
}

function Stop-BuildVm {
    param(
        [string]$PcBase,
        [securestring]$PcSecret,
        [object]$Vm
    )

    $power = [string]$Vm.status.resources.power_state
    if ($power -eq "OFF") {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] VM '$VmName' is already powered off."
        return
    }

    if ($PrismElementEndpoint) {
        $peSecret = $(if ($PrismElementPassword) { $PrismElementPassword } else { $PcSecret })
        $peBase = "https://$($PrismElementEndpoint.TrimEnd('/')):9440"
        $uuid = $Vm.metadata.uuid
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Requesting ACPI shutdown of '$VmName' ($uuid)."
        try {
            $acpi = Invoke-NutanixApi -Base $peBase -Path "/PrismGateway/services/rest/v2.0/vms/$uuid/set_power_state" `
                -Method Post -Secret $peSecret -Body @{ transition = "ACPI_SHUTDOWN" }
            $acpiTask = Get-TaskUuidFromResponse $acpi
            if ($acpiTask) { Wait-PrismTask -Base $peBase -TaskUuid $acpiTask -Secret $peSecret | Out-Null }
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ACPI shutdown was not accepted; forcing power off."
        }
    }

    $deadline = (Get-Date).AddMinutes(15)
    do {
        Start-Sleep -Seconds 10
        $current = Invoke-NutanixApi -Base $PcBase -Path "/api/nutanix/v3/vms/$($Vm.metadata.uuid)" -Secret $PcSecret
        $power = [string]$current.status.resources.power_state
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] VM power state: $power."
        if ($power -eq "OFF") { return }
    } while ((Get-Date) -lt $deadline)

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Guest did not power off in time; forcing OFF through Prism Central."
    $payload = @{
        spec        = $current.spec
        metadata    = $current.metadata
        api_version = $current.api_version
    }
    $payload.spec.resources.power_state = "OFF"
    $forced = Invoke-NutanixApi -Base $PcBase -Path "/api/nutanix/v3/vms/$($Vm.metadata.uuid)" -Method Put -Secret $PcSecret -Body $payload
    $forceTask = Get-TaskUuidFromResponse $forced
    if ($forceTask) { Wait-PrismTask -Base $PcBase -TaskUuid $forceTask -Secret $PcSecret | Out-Null }

    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 5
        $current = Invoke-NutanixApi -Base $PcBase -Path "/api/nutanix/v3/vms/$($Vm.metadata.uuid)" -Secret $PcSecret
        if ([string]$current.status.resources.power_state -eq "OFF") { return }
    } while ((Get-Date) -lt $deadline)
    throw "VM '$VmName' is still powered on; Citrix cannot snapshot it into a template."
}

function Find-V4Template {
    param([string]$Base, [securestring]$Secret, [string]$Name)

    $list = Invoke-NutanixApi -Base $Base -Path "/api/vmm/v4.0/content/templates" -Secret $Secret
    return @($list.data) | Where-Object { $_.templateName -eq $Name } | Select-Object -First 1
}

function Publish-V4Template {
    param([string]$Base, [securestring]$Secret, [string]$VmUuid)

    $existing = Find-V4Template -Base $Base -Secret $Secret -Name $TemplateName
    $versionSource = [ordered]@{
        extId        = $VmUuid
        '$objectType' = "vmm.v4.content.TemplateVmReference"
    }

    if ($existing) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Adding version '$VersionName' to template '$TemplateName' ($($existing.extId))."
        try {
            $response = Invoke-NutanixApi -Base $Base -Path "/api/vmm/v4.0/content/templates/$($existing.extId)/versions" `
                -Method Post -Secret $Secret -Body ([ordered]@{
                    versionName        = $VersionName
                    versionDescription = $VersionDescription
                    isActiveVersion    = $true
                    versionSource      = $versionSource
                })
            return @{ response = $response; templateExtId = $existing.extId; created = $false }
        } catch {
            $code = Get-NutanixStatusCode $_
            if ($code -notin 404, 405) { throw }
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Template version API is not available ($code); replacing '$TemplateName'."
            Invoke-NutanixApi -Base $Base -Path "/api/vmm/v4.0/content/templates/$($existing.extId)" -Method Delete -Secret $Secret | Out-Null
        }
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Creating Prism Central template '$TemplateName' from VM $VmUuid."
    $response = Invoke-NutanixApi -Base $Base -Path "/api/vmm/v4.0/content/templates" -Method Post -Secret $Secret -Body ([ordered]@{
        templateName        = $TemplateName
        templateDescription = $VersionDescription
        templateVersionSpec = [ordered]@{
            versionName        = $VersionName
            versionDescription = $VersionDescription
            isActiveVersion    = $true
            versionSource      = $versionSource
        }
    })
    $extId = $response.data.extId
    if (-not $extId) { $extId = $response.extId }
    return @{ response = $response; templateExtId = $extId; created = $true }
}

function Find-V3Template {
    param([string]$Base, [securestring]$Secret, [string]$Name)

    $list = Invoke-NutanixApi -Base $Base -Path "/api/nutanix/v3/vm_templates/list" -Method Post -Secret $Secret -Body @{
        kind   = "vm_template"
        length = 100
    }
    return @($list.entities) | Where-Object { $_.spec.name -eq $Name } | Select-Object -First 1
}

function Publish-V3Template {
    param([string]$Base, [securestring]$Secret, [string]$VmUuid)

    $existing = Find-V3Template -Base $Base -Secret $Secret -Name $TemplateName
    if ($existing) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Replacing v3 template '$TemplateName' so Citrix sees a new master."
        $delete = Invoke-NutanixApi -Base $Base -Path "/api/nutanix/v3/vm_templates/$($existing.metadata.uuid)" -Method Delete -Secret $Secret
        $deleteTask = Get-TaskUuidFromResponse $delete
        if ($deleteTask) { Wait-PrismTask -Base $Base -TaskUuid $deleteTask -Secret $Secret | Out-Null }
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Creating v3 VM template '$TemplateName' from VM $VmUuid."
    $response = Invoke-NutanixApi -Base $Base -Path "/api/nutanix/v3/vm_templates" -Method Post -Secret $Secret -Body @{
        api_version = "3.1.0"
        metadata    = @{ kind = "vm_template" }
        spec        = @{
            name        = $TemplateName
            description = $VersionDescription
            resources   = @{
                template_version_spec = @{
                    version_name        = $VersionName
                    version_description = $VersionDescription
                    version_source      = @{
                        entity_type = "VM"
                        entity_uuid = $VmUuid
                    }
                }
            }
        }
    }
    return @{ response = $response; templateExtId = $response.metadata.uuid; created = $true }
}

$pcBase = "https://$($PrismCentralEndpoint.TrimEnd('/')):9440"
$pcSecret = $Password

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Publishing '$VmName' as Prism Central template '$TemplateName' ($VersionName)."
$vm = Find-PrismCentralVm -Base $pcBase -Secret $pcSecret -Name $VmName
$vmUuid = $vm.metadata.uuid
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Found VM '$VmName' ($vmUuid)."
Stop-BuildVm -PcBase $pcBase -PcSecret $pcSecret -Vm $vm

$published = $null
try {
    $published = Publish-V4Template -Base $pcBase -Secret $pcSecret -VmUuid $vmUuid
} catch {
    $code = Get-NutanixStatusCode $_
    if ($code -in 404, 405, 501) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] VMM v4 templates are not available ($code); trying the v3 vm_templates API."
        $published = Publish-V3Template -Base $pcBase -Secret $pcSecret -VmUuid $vmUuid
    } else {
        throw
    }
}

$taskUuid = Get-TaskUuidFromResponse $published.response
if ($taskUuid -and $taskUuid -ne $published.templateExtId) {
    Wait-PrismTask -Base $pcBase -TaskUuid $taskUuid -Secret $pcSecret | Out-Null
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Template '$TemplateName' is ready for the Citrix machine catalog (uuid: $($published.templateExtId))."
[pscustomobject]@{
    vm_name        = $VmName
    vm_uuid        = $vmUuid
    template_name  = $TemplateName
    template_uuid  = $published.templateExtId
    version_name   = $VersionName
} | ConvertTo-Json
