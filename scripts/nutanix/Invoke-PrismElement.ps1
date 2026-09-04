[CmdletBinding(DefaultParameterSetName = "Vm")]
param(
    [Parameter(Mandatory = $true)]
    [string]$Endpoint,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [securestring]$Password,

    [Parameter(Mandatory = $true, ParameterSetName = "Vm")]
    [ValidateSet("CreateVm", "DeleteVm", "GetVm", "RestartVm", "PowerOnVm")]
    [string]$Action,

    [Parameter(Mandatory = $true, ParameterSetName = "Image")]
    [ValidateSet("CreateImage", "DeleteImage")]
    [string]$ImageAction,

    [string]$Name,
    [string]$Uuid,
    [string]$ClusterUuid,
    [string]$StorageContainerUuid,
    [string]$SubnetUuid,
    [string]$ImageUuid,
    [string]$ImageSourceUri,
    [int]$Cpu = 2,
    [int]$MemoryMiB = 4096,
    [int]$DiskSizeGiB = 100,
    [string]$SysprepUnattendPath,
    [string]$CloudInitPath,
    [switch]$SkipCertificateCheck,
    [int]$TaskTimeoutSeconds = 1800
)

$ErrorActionPreference = "Stop"

function Get-PrismHeaders {
    $plainPassword = [System.Net.NetworkCredential]::new("", $Password).Password
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${plainPassword}"))
    @{ Authorization = "Basic $token"; Accept = "application/json" }
}

function Invoke-PrismRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet("Get", "Post", "Put", "Delete")][string]$Method = "Get",
        [object]$Body
    )

    $parameters = @{
        Uri         = "https://$($Endpoint.TrimEnd('/')):9440$Path"
        Method      = $Method
        Headers     = Get-PrismHeaders
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

function Wait-PrismTask {
    param([string]$TaskUuid)

    $deadline = (Get-Date).AddSeconds($TaskTimeoutSeconds)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Waiting for Prism task $TaskUuid (timeout: $TaskTimeoutSeconds seconds)."
    do {
        $task = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/tasks/$TaskUuid"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism task $TaskUuid status: $($task.progress_status) ($($task.percentage_complete)%)."
        if ($task.progress_status -in @("Failed", "Aborted")) {
            throw "Prism task $TaskUuid ended with $($task.progress_status): $($task.meta_response.error_detail)"
        }
        if ($task.progress_status -eq "Succeeded") {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism task $TaskUuid completed."
            return $task
        }
        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for Prism task $TaskUuid."
}

function Get-TaskUuid {
    param([object]$Response)

    if ($Response.task_uuid) { return $Response.task_uuid }
    if ($Response.status.execution_context.task_uuid) { return $Response.status.execution_context.task_uuid }
    if ($Response.metadata.uuid) { return $Response.metadata.uuid }
    throw "Prism did not return an asynchronous task UUID."
}

if ($PSCmdlet.ParameterSetName -eq "Image") {
    if ($ImageAction -eq "CreateImage") {
        if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($ImageSourceUri) -or
            [string]::IsNullOrWhiteSpace($StorageContainerUuid)) {
            throw "CreateImage requires -Name, -ImageSourceUri, and -StorageContainerUuid."
        }
        $existingImage = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/images/").entities |
            Where-Object { $_.name -eq $Name } | Select-Object -First 1
        if ($existingImage) {
            $existingImage | ConvertTo-Json -Depth 20
            exit 0
        }
        $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/images/" -Method Post -Body @{
            name             = $Name
            annotation       = "GO-EUC Nutanix image"
            image_type       = "DISK_IMAGE"
            image_import_spec = @{
                url                    = $ImageSourceUri
                storage_container_uuid = $StorageContainerUuid
            }
        }
        Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | ConvertTo-Json -Depth 20
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($Uuid)) { throw "DeleteImage requires -Uuid." }
    $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/images/$Uuid" -Method Delete
    Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | ConvertTo-Json -Depth 20
    exit 0
}

if ($Action -eq "GetVm") {
    if ([string]::IsNullOrWhiteSpace($Uuid)) { throw "GetVm requires -Uuid." }
    Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$Uuid" | ConvertTo-Json -Depth 20
    exit 0
}

if ($Action -eq "DeleteVm") {
    if ([string]::IsNullOrWhiteSpace($Uuid) -and [string]::IsNullOrWhiteSpace($Name)) {
        throw "DeleteVm requires -Uuid or -Name."
    }
    if ([string]::IsNullOrWhiteSpace($Uuid)) {
        $existingVm = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/").entities |
            Where-Object { $_.name -eq $Name } | Select-Object -First 1
        if (!$existingVm) {
            Write-Output "{}"
            exit 0
        }
        $Uuid = $existingVm.uuid
    }
    $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$Uuid" -Method Delete
    Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | ConvertTo-Json -Depth 20
    exit 0
}

if ($Action -eq "PowerOnVm") {
    if ([string]::IsNullOrWhiteSpace($Uuid) -and [string]::IsNullOrWhiteSpace($Name)) {
        throw "PowerOnVm requires -Uuid or -Name."
    }
    if ([string]::IsNullOrWhiteSpace($Uuid)) {
        $existingVm = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/").entities |
            Where-Object { $_.name -eq $Name } | Select-Object -First 1
        if (!$existingVm) {
            throw "PowerOnVm could not find VM '$Name'."
        }
        $Uuid = $existingVm.uuid
        $powerState = "$($existingVm.power_state)".ToUpperInvariant()
    } else {
        $existingVm = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$Uuid"
        $powerState = "$($existingVm.power_state)".ToUpperInvariant()
        if ([string]::IsNullOrWhiteSpace($Name)) {
            $Name = $existingVm.name
        }
    }
    if ($powerState -eq "ON") {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] VM '$Name' ($Uuid) is already powered on."
        $existingVm | ConvertTo-Json -Depth 20
        exit 0
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Powering on VM '$Name' ($Uuid)."
    $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$Uuid/set_power_state" `
        -Method Post -Body @{ transition = "ON" }
    Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | ConvertTo-Json -Depth 20
    exit 0
}

if ($Action -eq "RestartVm") {
    if ([string]::IsNullOrWhiteSpace($Uuid) -and [string]::IsNullOrWhiteSpace($Name)) {
        throw "RestartVm requires -Uuid or -Name."
    }
    if ([string]::IsNullOrWhiteSpace($Uuid)) {
        $existingVm = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/").entities |
            Where-Object { $_.name -eq $Name } | Select-Object -First 1
        if (!$existingVm) {
            throw "RestartVm could not find VM '$Name'."
        }
        $Uuid = $existingVm.uuid
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Restarting VM '$Name' ($Uuid)."
    $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$Uuid/set_power_state" `
        -Method Post -Body @{ transition = "RESET" }
    Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | ConvertTo-Json -Depth 20
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($ClusterUuid) -or
    [string]::IsNullOrWhiteSpace($SubnetUuid) -or [string]::IsNullOrWhiteSpace($ImageUuid)) {
    throw "CreateVm requires -Name, -ClusterUuid, -SubnetUuid, and -ImageUuid."
}

$existingVm = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/").entities |
    Where-Object { $_.name -eq $Name } | Select-Object -First 1
if ($existingVm) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reusing existing VM '$Name' ($($existingVm.uuid))."
    $vmInstance = $existingVm
} else {
    $vm = @{
        name                = $Name
        num_vcpus           = $Cpu
        num_cores_per_vcpu  = 1
        memory_mb           = $MemoryMiB
        hypervisor_type     = "ACROPOLIS"
        timezone            = "UTC"
        boot                = @{
            uefi_boot         = $false
            boot_device_order = @("CDROM", "DISK", "NIC")
        }
        vm_features = @{ AGENT_VM = $false }
        vm_disks            = @(
            @{
                is_cdrom      = $false
                disk_address  = @{ device_bus = "scsi" }
                vm_disk_clone = @{
                    disk_address = @{ vmdisk_uuid = $ImageUuid }
                    minimum_size = $DiskSizeGiB * 1GB
                }
            }
        )
        vm_nics = @(@{
            network_uuid = $SubnetUuid
            is_connected = $true
        })
    }

    if ($SysprepUnattendPath) {
        # The Element v2 API has no dedicated sysprep field (that is v3 only):
        # the unattend XML is passed as plain-text userdata, the same way the
        # Prism UI "Custom Script" option accepts a Windows answer file.
        $vm.vm_customization_config = @{
            userdata             = [IO.File]::ReadAllText($SysprepUnattendPath)
            files_to_inject_list = @()
        }
    }
    if ($CloudInitPath) {
        $vm.vm_customization_config = @{
            userdata             = [IO.File]::ReadAllText($CloudInitPath)
            files_to_inject_list = @()
        }
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Creating VM '$Name'."
    $response = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/" -Method Post -Body $vm
    Wait-PrismTask -TaskUuid (Get-TaskUuid $response) | Out-Null
    $vmInstance = (Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/").entities |
        Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if (!$vmInstance) {
        throw "Prism completed VM creation but '$Name' was not returned by the VM inventory."
    }
}

$powerState = "$($vmInstance.power_state)".ToUpperInvariant()
if ($powerState -ne "ON") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Powering on VM '$Name' ($($vmInstance.uuid))."
    $powerTask = Invoke-PrismRequest -Path "/PrismGateway/services/rest/v2.0/vms/$($vmInstance.uuid)/set_power_state" `
        -Method Post -Body @{ transition = "ON" }
    Wait-PrismTask -TaskUuid (Get-TaskUuid $powerTask) | Out-Null
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] VM '$Name' is already powered on."
}

$vmInstance | ConvertTo-Json -Depth 20
