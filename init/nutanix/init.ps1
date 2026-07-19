<#
.SYNOPSIS
    Bootstraps the GO-EUC lab control plane on a preconfigured Nutanix CE cluster.

.DESCRIPTION
    This is the Nutanix equivalent of init/init.ps1 (VMware). It talks directly to a
    Prism Element endpoint (not Prism Central) and performs the following stages:

      1. Probe Prism Element to confirm the required v2 APIs are available.
      2. Build a cloud-init payload for the control-plane VM (user, password,
         optional static IP via Netplan, Docker engine).
      3. Import an Ubuntu cloud image into Prism and create/reuse the
         control-plane VM ("docker" VM) from it.
      4. Wait for the VM's IP address (static or DHCP) via Prism, then connect
         over SSH with Posh-SSH.
      5. Start the control-plane containers: PostgreSQL (Terraform state),
         HashiCorp Vault (secrets), and NGINX (software store).
      6. Initialize/unseal Vault and seed it with the Nutanix lab configuration.
      7. Run the Terraform Azure DevOps bootstrap (project, pipelines, variables)
         using the PostgreSQL backend that was just created.
      8. Upload the local software store (if present) and start the Azure DevOps
         agent containers.

    The script is idempotent where practical: the Prism image is reused if it
    already exists, the VM is reused unless -RecreateControlPlaneVm is passed,
    and the containers are recreated on each run.

.PARAMETER SettingsFile
    Path to the settings JSON (see settings.example.json for the schema).

.PARAMETER AdoPat
    Azure DevOps Personal Access Token. Needs Read/Write/Manage on
    "Project and Team" and "Agent Pools".

.PARAMETER GitHubPat
    GitHub Personal Access Token with read access to the GO-EUC repositories.

.PARAMETER PrismPassword
    Password for the Prism Element user in the settings file.

.PARAMETER PrismCentralPassword
    Password for the Prism Central user in the settings file. Required when
    settings.json contains a prism_central section; the image pipeline uses
    Prism Central for Packer ISO builds.

.PARAMETER DockerPassword
    Optional password for the control-plane VM user. If omitted, a random
    password is generated for this run (it is stored in Vault either way).

.PARAMETER RecreateControlPlaneVm
    Deletes and recreates the control-plane VM before bootstrapping. Required
    when the cloud-init payload changes, because Prism only applies
    customization on the VM's first boot.

.EXAMPLE
    $prism = Read-Host -AsSecureString
    ./init.ps1 -SettingsFile settings.json -AdoPat $adoPat -GitHubPat $ghPat -PrismPassword $prism
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SettingsFile,
    [Parameter(Mandatory = $true)][string]$AdoPat,
    [Parameter(Mandatory = $true)][string]$GitHubPat,
    [Parameter(Mandatory = $true)][securestring]$PrismPassword,
    [securestring]$PrismCentralPassword,
    [securestring]$DockerPassword,
    [switch]$RecreateControlPlaneVm
)

# Fail fast: any uncaught error aborts the bootstrap instead of continuing
# with a half-configured control plane.
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# Timestamped progress logging for the major stages of the bootstrap.
function Write-Stage {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

$settings = Get-Content -Path $SettingsFile -Raw | ConvertFrom-Json

# Builds an absolute path from the repository root using OS-native separators,
# so the same settings file works on Windows and macOS/Linux.
function Get-PathFromRepositoryRoot {
    param([string[]]$ChildPath)

    Join-Path -Path $repoRoot -ChildPath ($ChildPath -join [IO.Path]::DirectorySeparatorChar)
}

# Returns a usable temp directory across platforms: Windows sets TEMP,
# macOS sets TMPDIR, and GetTempPath() covers everything else.
function Get-TemporaryPath {
    if ($env:TEMP) {
        return $env:TEMP
    }
    if ($env:TMPDIR) {
        return $env:TMPDIR
    }
    return [IO.Path]::GetTempPath()
}

# Resolves a host address inside a CIDR from an integer offset, e.g.
# Get-CidrHost -Cidr "192.168.1.0/24" -HostOffset 1 -> 192.168.1.1.
# The settings file stores gateway/DNS as offsets rather than full addresses.
function Get-CidrHost {
    param(
        [Parameter(Mandatory = $true)][string]$Cidr,
        [Parameter(Mandatory = $true)][int]$HostOffset
    )

    $parts = $Cidr.Split("/")
    $prefixLength = [int]$parts[1]
    $bytes = [Net.IPAddress]::Parse($parts[0]).GetAddressBytes()
    if ($bytes.Length -ne 4 -or $prefixLength -lt 0 -or $prefixLength -gt 32) {
        throw "'$Cidr' must be a valid IPv4 CIDR."
    }

    # Mask the address down to the network base, octet by octet.
    for ($index = 0; $index -lt $bytes.Length; $index++) {
        $bitsInOctet = [Math]::Min([Math]::Max($prefixLength - ($index * 8), 0), 8)
        $mask = if ($bitsInOctet -eq 0) { 0 } else { 256 - [Math]::Pow(2, 8 - $bitsInOctet) }
        $bytes[$index] = $bytes[$index] -band [byte]$mask
    }

    # Convert to an integer, add the host offset, and convert back.
    # BitConverter is little-endian, hence the byte reversals.
    [Array]::Reverse($bytes)
    $addressValue = [BitConverter]::ToUInt32($bytes, 0) + $HostOffset
    $result = [BitConverter]::GetBytes($addressValue)
    [Array]::Reverse($result)
    ([Net.IPAddress]::new($result)).IPAddressToString
}

# ---------------------------------------------------------------------------
# Repository root and prerequisites
# ---------------------------------------------------------------------------

# The script lives at <repo>/init/nutanix/init.ps1, so two directories up is
# the repository root. settings.repo_root can override this (useful when the
# settings file is shared between machines), but is ignored if the configured
# path does not exist on this host (e.g. a Windows path used on macOS).
$scriptRepositoryRoot = (Resolve-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)).Path
if ($settings.repo_root) {
    $configuredRepositoryRoot = $settings.repo_root -replace '[\\/]', [IO.Path]::DirectorySeparatorChar
    if (Test-Path $configuredRepositoryRoot) {
        $repoRoot = (Resolve-Path $configuredRepositoryRoot).Path
    } else {
        Write-Warning "Configured repo_root '$($settings.repo_root)' does not exist on this host. Using '$scriptRepositoryRoot'."
        $repoRoot = $scriptRepositoryRoot
    }
} else {
    $repoRoot = $scriptRepositoryRoot
}

# The two Prism Element helper scripts this bootstrap depends on:
# - Invoke-PrismElement.ps1: VM/image lifecycle adapter (create, delete, restart).
# - Test-PrismElement.ps1:   read-only capability probe.
$adapter = Get-PathFromRepositoryRoot -ChildPath @("scripts", "nutanix", "Invoke-PrismElement.ps1")
$probe = Get-PathFromRepositoryRoot -ChildPath @("scripts", "nutanix", "Test-PrismElement.ps1")

if (!(Test-Path $adapter) -or !(Test-Path $probe)) {
    throw "Nutanix scripts are missing. Run this from a checked-out GO-EUC-LAB repository."
}
Write-Stage "Using repository root '$repoRoot'."

# Prism Central is a deployment prerequisite (deployed once through the Prism
# Element UI) and drives the Packer ISO image builds. Its credentials are
# seeded into Vault below so the image pipeline can authenticate.
if ($settings.prism_central -and -not $PrismCentralPassword) {
    throw "settings.json contains a prism_central section; pass its password with -PrismCentralPassword."
}
if (!$settings.prism_central) {
    Write-Warning "No prism_central section in settings.json. The Nutanix image pipeline requires Prism Central; deploy it from Prism Element and rerun with the section configured."
}

# Posh-SSH provides cross-platform SSH/SFTP (Windows and macOS/Linux).
if (!(Get-Module -ListAvailable -Name Posh-SSH)) {
    Write-Stage "Installing required Posh-SSH module."
    Install-Module -Name Posh-SSH -Scope CurrentUser -Force -Confirm:$false
}
Import-Module Posh-SSH

# ---------------------------------------------------------------------------
# Posh-SSH helpers
# ---------------------------------------------------------------------------

function Clear-PoshSshTrustedHost {
    param([Parameter(Mandatory = $true)][string]$HostName)

    # Recreated VMs reuse the same IP with a new host key. Posh-SSH reports that
    # mismatch as "Key exchange negotiation failed" unless the cached entry is removed.
    $trustedHost = Get-SSHTrustedHost -HostName $HostName -ErrorAction SilentlyContinue
    if ($trustedHost) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Removing stale Posh-SSH trusted host entry for $HostName."
        Remove-SSHTrustedHost -HostName $HostName | Out-Null
    }
}

function ConvertFrom-PoshSshJson {
    param($Output)

    # Posh-SSH returns stdout as a string array; ConvertFrom-Json must receive one document.
    if ($null -eq $Output) {
        return $null
    }
    $json = if ($Output -is [string]) { $Output } else { ($Output | Out-String).Trim() }
    if ([string]::IsNullOrWhiteSpace($json)) {
        return $null
    }

    # Prefer the first JSON object if the stream also contains log noise.
    $match = [regex]::Match($json, '(?s)\{.*\}')
    if (!$match.Success) {
        return $null
    }
    try {
        return ($match.Value | ConvertFrom-Json)
    } catch {
        return $null
    }
}

# Flattens a Posh-SSH command result (stdout + stderr arrays) into one string,
# mainly for building readable error messages and log lines.
function Get-PoshSshText {
    param($CommandResult)

    if (!$CommandResult) {
        return ""
    }
    $parts = @()
    if ($CommandResult.Output) { $parts += ($CommandResult.Output | Out-String) }
    if ($CommandResult.Error) { $parts += ($CommandResult.Error | Out-String) }
    return ($parts -join "`n").Trim()
}

# ---------------------------------------------------------------------------
# Stage 1: Verify the Prism Element endpoint
# ---------------------------------------------------------------------------

# The probe is read-only. It confirms the cluster/network/VM v2 APIs exist
# before anything is created; CE releases differ in what they expose.
Write-Stage "Checking Prism Element capabilities at $($settings.prism.endpoint)."
$capabilities = & $probe -Endpoint $settings.prism.endpoint -Username $settings.prism.username `
    -Password $PrismPassword -SkipCertificateCheck:$settings.prism.insecure
if (!$capabilities.api.cluster -or !$capabilities.api.networks -or !$capabilities.api.virtual_machines) {
    throw "Prism Element does not expose the minimum cluster, network, and VM APIs required by this bootstrap."
}

# ---------------------------------------------------------------------------
# Stage 2: Build the cloud-init payload for the control-plane VM
# ---------------------------------------------------------------------------

Write-Stage "Creating cloud-init data for the control-plane VM."

# The control-plane user password: caller-supplied or generated per run.
# Either way it is later stored in Vault under go/docker.
if ($DockerPassword) {
    $dockerPlaintextPassword = [Net.NetworkCredential]::new("", $DockerPassword).Password
    Write-Stage "Using the caller-supplied control-plane password."
} else {
    $dockerPlaintextPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789'.ToCharArray() | Get-Random -Count 20)
    Write-Stage "Generated a control-plane password for this initialization run."
}

$cloudInit = Join-Path (Get-TemporaryPath) "go-euc-nutanix-cloud-init.yaml"

# Optional static addressing. Prism Element cannot inject Config Drive network
# metadata, so the documented workaround is used instead: cloud-init overwrites
# the DHCP Netplan file (/etc/netplan/50-cloud-init.yaml) with a static
# configuration, then `netplan generate && netplan apply` run from runcmd.
# The VM therefore boots on DHCP first and switches to the static address
# late in first boot; the wait loop below accounts for that transition.
$staticNetworkConfiguration = ""
$staticIp = $null
if ($settings.docker.static_ip) {
    $staticIp = $settings.docker.static_ip
    try {
        [void][Net.IPAddress]::Parse($staticIp)
    } catch {
        throw "docker.static_ip '$staticIp' is not a valid IPv4 address."
    }

    $prefixLength = [int]$settings.network.cidr.Split("/")[1]
    $gatewayIp = Get-CidrHost -Cidr $settings.network.cidr -HostOffset $settings.network.gateway
    Write-Stage "Configuring static control-plane address $staticIp/$prefixLength."

    # match "e*" + set-name pins the AHV virtio NIC (usually ens3) regardless
    # of the name the kernel assigns on first boot. Google DNS keeps external
    # resolution working after the VM leaves DHCP.
    $staticNetworkConfiguration = @"
write_files:
  - path: /etc/netplan/50-cloud-init.yaml
    permissions: '0600'
    content: |
      network:
        version: 2
        renderer: networkd
        ethernets:
          e:
            match:
              name: "e*"
            set-name: ens3
            dhcp4: false
            addresses:
              - $staticIp/$prefixLength
            routes:
              - to: default
                via: $gatewayIp
            nameservers:
              addresses:
                - 8.8.8.8
                - 8.8.4.4
"@
}

# The full first-boot payload: create the admin user with password SSH auth,
# apply the optional static network, install Docker, and start it.
# NOTE: Prism only applies this on the VM's FIRST boot. Changing it requires
# -RecreateControlPlaneVm.
@"
#cloud-config
users:
  - name: $($settings.docker.user)
    groups: [sudo, docker]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
ssh_pwauth: true
chpasswd:
  expire: false
  users:
    - name: $($settings.docker.user)
      password: $dockerPlaintextPassword
      type: text
$staticNetworkConfiguration
package_update: true
packages: [docker.io]
runcmd:
  - netplan generate
  - netplan apply
  - systemctl enable --now docker
"@ | Set-Content -Path $cloudInit -Encoding utf8

# ---------------------------------------------------------------------------
# Stage 3: Import the Ubuntu image and create the control-plane VM
# ---------------------------------------------------------------------------

# The adapter reuses the image if it already exists, so this is cheap on reruns.
$imageName = "go-euc-ubuntu-control-plane"
Write-Stage "Ensuring Prism image '$imageName' is available."
& $adapter -ImageAction CreateImage -Endpoint $settings.prism.endpoint -Username $settings.prism.username `
    -Password $PrismPassword -Name $imageName -ImageSourceUri $settings.docker.image_source_uri `
    -StorageContainerUuid $settings.prism.storage_container_uuid -SkipCertificateCheck:$settings.prism.insecure | Out-Null

# Minimal authenticated GET against the Prism Element v2 REST API.
function Invoke-PrismRead {
    param([string]$Path)
    $plain = [Net.NetworkCredential]::new("", $PrismPassword).Password
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($settings.prism.username):$plain"))
    Invoke-RestMethod -Uri "https://$($settings.prism.endpoint):9440$Path" -Headers @{ Authorization = "Basic $token" } `
        -SkipCertificateCheck:$settings.prism.insecure
}

# Reads the first IPv4 address Prism reports for a VM's NICs.
# include_vm_nic_config=true is required for Prism to include DHCP lease
# addresses in vm_nics[].ip_address.
function Get-PrismVmIpv4Address {
    param([Parameter(Mandatory = $true)][string]$VmName)

    $vm = (Invoke-PrismRead "/PrismGateway/services/rest/v2.0/vms/?include_vm_nic_config=true").entities |
        Where-Object { $_.name -eq $VmName } | Select-Object -First 1
    if (!$vm) {
        return $null
    }

    $vm.vm_nics |
        ForEach-Object { $_.ip_address } |
        Where-Object { $_ -and $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } |
        Select-Object -First 1
}

# Prism Element clones VMs from a specific image *disk* (vm_disk_id), not the
# image UUID itself, so look it up now that the image exists.
Write-Stage "Looking up the control-plane image disk."
$images = Invoke-PrismRead "/PrismGateway/services/rest/v2.0/images/"
$image = $images.entities | Where-Object { $_.name -eq $imageName } | Select-Object -First 1
if (!$image) { throw "Prism completed the image task but did not return '$imageName'." }
if ([string]::IsNullOrWhiteSpace($image.vm_disk_id)) {
    throw "Prism image '$imageName' does not expose a vm_disk_id required for Prism Element VM cloning."
}

# Cloud-init only applies on first boot, so an updated payload requires the
# VM to be deleted and recreated. This is opt-in to protect existing state.
if ($RecreateControlPlaneVm) {
    $existingControlPlaneVm = (Invoke-PrismRead "/PrismGateway/services/rest/v2.0/vms/").entities |
        Where-Object { $_.name -eq $settings.docker.name } | Select-Object -First 1
    if ($existingControlPlaneVm) {
        Write-Stage "Deleting existing control-plane VM '$($settings.docker.name)' so updated cloud-init can apply."
        & $adapter -Action DeleteVm -Endpoint $settings.prism.endpoint -Username $settings.prism.username `
            -Password $PrismPassword -Name $settings.docker.name -SkipCertificateCheck:$settings.prism.insecure | Out-Null
    }
}

# The adapter reuses an existing VM by name, otherwise clones the image disk,
# attaches the subnet NIC, injects cloud-init, and powers the VM on.
Write-Stage "Creating or reusing control-plane VM '$($settings.docker.name)'."
& $adapter -Action CreateVm -Endpoint $settings.prism.endpoint -Username $settings.prism.username `
    -Password $PrismPassword -Name $settings.docker.name -ClusterUuid $settings.prism.cluster_uuid `
    -SubnetUuid $settings.prism.subnet_uuid -ImageUuid $image.vm_disk_id -CloudInitPath $cloudInit `
    -DiskSizeGiB 512 -SkipCertificateCheck:$settings.prism.insecure | Out-Null

# ---------------------------------------------------------------------------
# Stage 4: Wait for the VM's address and establish SSH
# ---------------------------------------------------------------------------

$dockerCredential = [pscredential]::new($settings.docker.user, (ConvertTo-SecureString $dockerPlaintextPassword -AsPlainText -Force))
$sshDeadline = (Get-Date).AddMinutes(10)

if ($staticIp) {
    # Static path: the VM boots on DHCP, then cloud-init applies Netplan and
    # the address flips to the configured static IP. Wait for Prism to report
    # the static address BEFORE attempting SSH — connecting mid-transition
    # produces confusing failures.
    $staticAddressDeadline = (Get-Date).AddMinutes(5)
    Write-Stage "Waiting for Prism to report configured static address $staticIp before connecting (timeout: 5 minutes)."
    do {
        Start-Sleep -Seconds 5
        $reportedIp = Get-PrismVmIpv4Address -VmName $settings.docker.name
        if ($reportedIp -eq $staticIp) {
            $dockerIp = $staticIp
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism reports configured static address $staticIp."
        } elseif ($reportedIp) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism still reports DHCP address $reportedIp; waiting for $staticIp."
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism has not reported an address while Netplan is applying."
        }
        if ((Get-Date) -gt $staticAddressDeadline) {
            throw "Cloud-init did not apply static address $staticIp. Inspect /var/log/cloud-init-output.log and /etc/netplan/50-cloud-init.yaml from the Prism console."
        }
    } until ($dockerIp)

    # Reboot once the static address is live. This gives the guest a clean
    # start on its final address (fresh sshd, no half-applied network state)
    # before the bootstrap connects.
    Write-Stage "Restarting the control-plane VM after the static address is available."
    & $adapter -Action RestartVm -Endpoint $settings.prism.endpoint -Username $settings.prism.username `
        -Password $PrismPassword -Name $settings.docker.name -SkipCertificateCheck:$settings.prism.insecure | Out-Null
    $sshDeadline = (Get-Date).AddMinutes(10)
    Write-Stage "Waiting for SSH at static address $dockerIp after the restart (timeout: 10 minutes)."
} else {
    # DHCP path: whatever address Prism reports is the address used.
    Write-Stage "Waiting for Prism to report a DHCP address and for SSH to become available (timeout: 10 minutes)."
}

# Retry SSH until the guest is ready. "Connection refused" while sshd starts
# is expected; each new address gets its stale trusted-host entry cleared once.
$clearedTrustedHosts = @{}
do {
    Start-Sleep -Seconds 5
    if (!$dockerIp) {
        $dockerIp = Get-PrismVmIpv4Address -VmName $settings.docker.name
    }
    if ($dockerIp) {
        if (-not $clearedTrustedHosts.ContainsKey($dockerIp)) {
            Clear-PoshSshTrustedHost -HostName $dockerIp
            $clearedTrustedHosts[$dockerIp] = $true
        }
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism reports control-plane IP $dockerIp; testing SSH."
        try {
            # -Force skips host key verification: the VM was just created by
            # this script, and recreated VMs always present a new host key.
            $session = New-SSHSession -ComputerName $dockerIp -Credential $dockerCredential -AcceptKey -Force -ErrorAction Stop
        } catch {
            $session = $null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] SSH authentication for '$($settings.docker.user)' failed: $($_.Exception.Message)"
        }
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Prism has not reported a DHCP address yet."
    }
    if (!$session -and $dockerIp) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] SSH is not ready yet."
    }
    if ((Get-Date) -gt $sshDeadline) {
        throw "Timed out waiting for SSH on control-plane VM $dockerIp."
    }
} until ($session)
Write-Stage "Connected to the control-plane VM at $dockerIp."

# ---------------------------------------------------------------------------
# Stage 5: Start the control-plane containers
# ---------------------------------------------------------------------------

# SFTP session for file uploads (Vault config now, software store later).
$sftpSession = New-SFTPSession -ComputerName $dockerIp -Credential $dockerCredential -AcceptKey -Force
Write-Stage "Uploading Vault configuration."
# Upload to /tmp first; the gouser SFTP session cannot write to /etc directly.
Set-SFTPItem -SFTPSession $sftpSession -Path (Get-PathFromRepositoryRoot -ChildPath @("init", "data", "vault", "config.hcl")) -Destination "/tmp/" -Force

# Generate this run's secrets. All of them are persisted to Vault below, so
# losing the console output is not fatal.
$postgresPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789'.ToCharArray() | Get-Random -Count 20)
$ansiblePassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#'.ToCharArray() | Get-Random -Count 20)
$loadgenPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#'.ToCharArray() | Get-Random -Count 20)
$loadgenBotPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#'.ToCharArray() | Get-Random -Count 20)
$sqlAgentPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#'.ToCharArray() | Get-Random -Count 20)
$sqlServicePassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#'.ToCharArray() | Get-Random -Count 20)

# Container bootstrap commands. Each `docker rm -f` first makes the run
# idempotent — rerunning replaces the containers instead of failing on
# duplicate names.
$bootstrap = @(
    # Directory layout: /etc/postgresql (PG data), /etc/vault (Vault config/
    # storage/logs, mounted at /vault in-container), /go (NGINX software store).
    "sudo mkdir -p /etc/postgresql /etc/vault/config /etc/vault/file /etc/vault/logs /go && sudo mv /tmp/config.hcl /etc/vault/config/config.hcl && sudo chmod -R a+rwx /etc/vault /go",
    # Pin Postgres 16: postgres:latest (18+) changed the expected bind-mount path and breaks this layout.
    # The data dir is wiped and re-owned by UID 999 (the postgres user in the
    # image) because a new POSTGRES_PASSWORD only applies to a fresh data dir.
    "docker rm -f postgres >/dev/null 2>&1; sudo rm -rf /etc/postgresql; sudo mkdir -p /etc/postgresql && sudo chown 999:999 /etc/postgresql && sudo chmod 700 /etc/postgresql; docker run -d --restart unless-stopped -v /etc/postgresql:/var/lib/postgresql/data -e POSTGRES_USER=tf -e POSTGRES_PASSWORD=$postgresPassword -e POSTGRES_DB=state -p 5432:5432 --name postgres postgres:16",
    # SKIP_SETCAP avoids the entrypoint's mlock setcap, which fails on this
    # guest; config.hcl sets disable_mlock accordingly.
    "docker rm -f vault >/dev/null 2>&1; docker run -d --restart unless-stopped -v /etc/vault:/vault --cap-add=IPC_LOCK -e SKIP_SETCAP=true -p 8200:8200 --name vault hashicorp/vault:latest server",
    # NGINX serves /go as the lab software store on port 8080.
    "docker rm -f nginx >/dev/null 2>&1; docker run -d --restart unless-stopped -v /go:/usr/share/nginx/html -p 8080:80 --name nginx nginx:latest"
)
Write-Stage "Starting PostgreSQL, Vault, and NGINX containers."
foreach ($command in $bootstrap) {
    $bootstrapResult = Invoke-SSHCommand -SSHSession $session -Command $command -TimeOut 300
    if ($bootstrapResult.ExitStatus -ne 0) {
        throw "Remote bootstrap command failed ($($bootstrapResult.ExitStatus)): $command`n$(Get-PoshSshText -CommandResult $bootstrapResult)"
    }
}

# ---------------------------------------------------------------------------
# Stage 6: Initialize, unseal, and seed Vault
# ---------------------------------------------------------------------------

$vaultDeadline = (Get-Date).AddMinutes(5)
Write-Stage "Waiting for Vault to become available (timeout: 5 minutes)."
$vaultInit = $null
do {
    Start-Sleep -Seconds 2
    # vault status exits 2 when sealed/uninitialized but still emits JSON on stdout.
    # VAULT_ADDR must be http; the CLI defaults to https and otherwise returns no JSON.
    $vaultStatus = Invoke-SSHCommand -SSHSession $session `
        -Command "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault sh -c 'vault status -format=json || true'" `
        -ErrorAction SilentlyContinue
    $vaultInit = ConvertFrom-PoshSshJson -Output (Get-PoshSshText -CommandResult $vaultStatus)
    if (!$vaultInit) {
        # Include the container state in the wait message to make crash loops
        # visible from the bootstrap log.
        $containerState = Invoke-SSHCommand -SSHSession $session `
            -Command "docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' vault 2>/dev/null || echo missing" `
            -ErrorAction SilentlyContinue
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Vault is not ready yet (container: $((Get-PoshSshText -CommandResult $containerState)))."
    }
    if ((Get-Date) -gt $vaultDeadline) {
        $vaultLogs = Invoke-SSHCommand -SSHSession $session -Command "docker logs --tail 40 vault 2>&1" -ErrorAction SilentlyContinue
        throw "Timed out waiting for Vault to start.`n$(Get-PoshSshText -CommandResult $vaultLogs)"
    }
} until ($vaultInit)

# First run: initialize Vault and capture the unseal keys plus root token.
# On reruns against an initialized Vault, the status output already contains
# initialized=true, but the unseal keys are only returned by `operator init`,
# so reruns generally pair with -RecreateControlPlaneVm for a clean Vault.
if (!$vaultInit.initialized) {
    Write-Stage "Initializing Vault."
    $vaultInitResult = Invoke-SSHCommand -SSHSession $session `
        -Command "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator init -format=json"
    $vaultInit = ConvertFrom-PoshSshJson -Output (Get-PoshSshText -CommandResult $vaultInitResult)
    if (!$vaultInit -or !$vaultInit.root_token) {
        throw "Vault initialization did not return a usable JSON response.`n$(Get-PoshSshText -CommandResult $vaultInitResult)"
    }
}

# Vault requires 3 of the 5 unseal keys by default.
Write-Stage "Unsealing Vault."
foreach ($key in $vaultInit.unseal_keys_b64[0..2]) {
    Invoke-SSHCommand -SSHSession $session `
        -Command "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator unseal $key" | Out-Null
}
$vaultToken = $vaultInit.root_token

# All subsequent Vault CLI calls run inside the container with the root token.
$vaultPrefix = "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=$vaultToken vault vault"
Write-Stage "Creating Vault KV store and seeding Nutanix configuration."
# KV v1 at path "go" — the same layout the VMware path and the Ansible
# vault.yml playbook expect.
Invoke-SSHCommand -SSHSession $session -Command "$vaultPrefix secrets enable -version=1 -path=go kv" | Out-Null

# Seed secrets consumed by Terraform, Packer, and Ansible:
#   go/nutanix/*   - Prism connection and cluster/network/storage UUIDs
#   go/docker      - control-plane VM credentials and address
#   go/build       - build VM credentials
#   go/postgress   - Terraform state backend connection info
#   go/domain*     - lab domain name and service account passwords
# ("postgress" spelling is the repository-wide convention.)
$seed = @(
    "domain name=$($settings.domain_name)",
    "nutanix/prism endpoint=$($settings.prism.endpoint) username=$($settings.prism.username) password=$([Net.NetworkCredential]::new('', $PrismPassword).Password) insecure=$($settings.prism.insecure)",
    "nutanix/cluster uuid=$($settings.prism.cluster_uuid)",
    "nutanix/storage container_uuid=$($settings.prism.storage_container_uuid)",
    "nutanix/network cidr=$($settings.network.cidr) gateway=$($settings.network.gateway) dns=$($settings.network.dns) start=$($settings.network.start) end=$($settings.network.end) subnet_uuid=$($settings.prism.subnet_uuid)",
    "docker name=$($settings.docker.name) user=$($settings.docker.user) password=$dockerPlaintextPassword ip=$dockerIp",
    "build user=$($settings.build.user) ip=$($settings.build.ip) password=$dockerPlaintextPassword",
    "postgress user=tf password=$postgresPassword ip=$dockerIp database=state ssl=disable",
    "domain/accounts ansible=$ansiblePassword loadgen=$loadgenPassword loadgen_bot=$loadgenBotPassword sql_agt=$sqlAgentPassword sql_svc=$sqlServicePassword"
)
# Prism Central credentials feed the Packer ISO builds in the image pipeline.
if ($settings.prism_central) {
    $seed += "nutanix/prism_central endpoint=$($settings.prism_central.endpoint) username=$($settings.prism_central.username) password=$([Net.NetworkCredential]::new('', $PrismCentralPassword).Password) insecure=$($settings.prism_central.insecure)"
}
foreach ($secret in $seed) { Invoke-SSHCommand -SSHSession $session -Command "$vaultPrefix kv put -mount=go $secret" | Out-Null }

# ---------------------------------------------------------------------------
# Stage 7: Terraform Azure DevOps bootstrap
# ---------------------------------------------------------------------------

# Postgres must accept connections before Terraform can initialize its "pg"
# state backend; the container needs time to run initdb on first start.
$postgresDeadline = (Get-Date).AddMinutes(5)
Write-Stage "Waiting for PostgreSQL to accept connections (timeout: 5 minutes)."
do {
    Start-Sleep -Seconds 2
    $postgresReady = Invoke-SSHCommand -SSHSession $session `
        -Command "docker exec postgres pg_isready -U tf -d state" `
        -ErrorAction SilentlyContinue
    $postgresReadyText = Get-PoshSshText -CommandResult $postgresReady
    if ($postgresReadyText -match 'accepting connections') {
        break
    }
    $containerState = Invoke-SSHCommand -SSHSession $session `
        -Command "docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' postgres 2>/dev/null || echo missing" `
        -ErrorAction SilentlyContinue
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] PostgreSQL is not ready yet (container: $((Get-PoshSshText -CommandResult $containerState)); pg_isready: $postgresReadyText)."
    if ((Get-Date) -gt $postgresDeadline) {
        $postgresLogs = Invoke-SSHCommand -SSHSession $session -Command "docker logs --tail 40 postgres 2>&1" -ErrorAction SilentlyContinue
        throw "Timed out waiting for PostgreSQL.`n$(Get-PoshSshText -CommandResult $postgresLogs)"
    }
} while ($true)
Write-Stage "PostgreSQL is ready at ${dockerIp}:5432."

# Pipeline variables for the Azure DevOps project. Written to a temporary
# terraform.tfvars.json (deleted in the finally block) so secrets never land
# in the repository.
Write-Stage "Writing temporary Azure DevOps Terraform variables."
$adoVariables = @(
    @{ name = "postgress_user"; value = "tf"; is_secret = $false },
    @{ name = "postgress_password"; value = $postgresPassword; is_secret = $true },
    @{ name = "postgress_address"; value = $dockerIp; is_secret = $false },
    @{ name = "postgress_ssl"; value = "disable"; is_secret = $false },
    @{ name = "vault_token"; value = $vaultToken; is_secret = $true },
    @{ name = "vault_addr"; value = "http://${dockerIp}:8200"; is_secret = $false }
)
# The pipelines need three unseal keys to unseal Vault after a control-plane
# restart (see the unseal stage in the pipeline definitions).
for ($index = 0; $index -lt 3; $index++) {
    $adoVariables += @{ name = "vault_unseal_$($index + 1)"; value = $vaultInit.unseal_keys_b64[$index]; is_secret = $true }
}
$terraformDevOpsPath = Get-PathFromRepositoryRoot -ChildPath @("terraform", "devops")
$tfVarsPath = Join-Path $terraformDevOpsPath "terraform.tfvars.json"
@{ ado_variables = $adoVariables } | ConvertTo-Json -Depth 5 | Set-Content -Path $tfVarsPath -Encoding utf8

# PATs and the organization URL are passed via TF_VAR_* environment variables
# rather than files.
$env:TF_VAR_ado_pat = $AdoPat
$env:TF_VAR_ado_url = $settings.ado_url
$env:TF_VAR_github_pat = $GitHubPat

# Terraform state lives in the PostgreSQL container that was just started.
# -reconfigure tolerates connection strings changing between reruns.
$terraformBackend = "conn_str=postgres://tf:$postgresPassword@$dockerIp/state?sslmode=disable"
$terraformInitArguments = @("init", "-backend-config=$terraformBackend", "-reconfigure")
Push-Location $terraformDevOpsPath
try {
    Write-Stage "Initializing Terraform Azure DevOps bootstrap."
    & terraform @terraformInitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "terraform init failed with exit code $LASTEXITCODE."
    }
    Write-Stage "Creating Azure DevOps project and pipeline definitions."
    & terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply failed with exit code $LASTEXITCODE."
    }
} finally {
    # Always restore the working directory and remove the secrets file,
    # even when Terraform fails.
    Pop-Location
    Remove-Item -Path $tfVarsPath -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Stage 8: Software store upload and Azure DevOps agents
# ---------------------------------------------------------------------------

# Mirror the local software store into /go on the control plane, where NGINX
# serves it to the lab (installers, ISOs, etc.). Optional: skipped when the
# configured path does not exist on this machine.
if (Test-Path $settings.software_store) {
    Write-Stage "Uploading software store from '$($settings.software_store)'."
    foreach ($file in Get-ChildItem -Path $settings.software_store -Recurse -File) {
        # Rebuild the same relative directory layout under /go with POSIX separators.
        $relativeDirectory = $file.DirectoryName.Replace($settings.software_store, "").Replace("\", "/")
        Invoke-SSHCommand -SSHSession $session -Command "sudo mkdir -p '/go$relativeDirectory' && sudo chmod -R a+rwx /go" | Out-Null
        Set-SFTPItem -SFTPSession $sftpSession -Path $file.FullName -Destination "/go$relativeDirectory/" -Force
    }
}

# Start the self-hosted Azure DevOps agents that will run the lab pipelines.
# They register into the "GO Pipelines" pool, which the pipeline definitions target.
# Pull the agent image once up front: the first `docker run` otherwise does the
# pull itself and can exceed the SSH command timeout.
Write-Stage "Pulling the Azure DevOps agent image."
$pullResult = Invoke-SSHCommand -SSHSession $session -Command "docker pull goeuc/ado-agent:latest" -TimeOut 900
if ($pullResult.ExitStatus -ne 0) {
    throw "Failed to pull goeuc/ado-agent:latest.`n$(Get-PoshSshText -CommandResult $pullResult)"
}
Write-Stage "Starting $($settings.ado_agents) Azure DevOps agent container(s)."
for ($index = 1; $index -le $settings.ado_agents; $index++) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting agent-$index."
    # `docker rm -f` keeps reruns idempotent when the container already exists.
    # CAP_IPC_LOCK is required because the Vault CLI inside the agent image
    # carries the cap_ipc_lock file capability; without it, executing
    # /usr/bin/vault fails with "Operation not permitted".
    $agent = "docker rm -f agent$index >/dev/null 2>&1; docker run -d --restart unless-stopped --cap-add=CAP_IPC_LOCK -e AZP_URL='$($settings.ado_url)' -e AZP_TOKEN='$AdoPat' -e AZP_POOL='GO Pipelines' -e AZP_AGENT_NAME='agent-$index' --name agent$index goeuc/ado-agent:latest"
    $agentResult = Invoke-SSHCommand -SSHSession $session -Command $agent -TimeOut 300
    if ($agentResult.ExitStatus -ne 0) {
        throw "Failed to start agent-$index.`n$(Get-PoshSshText -CommandResult $agentResult)"
    }
}

# ---------------------------------------------------------------------------
# Wrap up
# ---------------------------------------------------------------------------

# The root token is required for any manual Vault administration; the unseal
# keys are stored as secret pipeline variables in Azure DevOps.
Write-Output "Control plane is ready. Vault root token: $vaultToken"
Write-Warning "Save the Vault token securely."

# Clean up the local cloud-init file (contains the control-plane password)
# and close the remote sessions.
Remove-Item -Path $cloudInit -Force -ErrorAction SilentlyContinue
Remove-SSHSession -SSHSession $session | Out-Null
Remove-SFTPSession -SFTPSession $sftpSession | Out-Null
