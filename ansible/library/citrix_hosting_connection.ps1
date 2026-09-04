#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

#Set-StrictMode -Version 2

Function Get-SSLThumbprint {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('FullName')]
    [String]$URL
    )

add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy

    try {
        Invoke-RestMethod -Uri $URL -Method Get -ErrorAction Stop | Out-Null
    } catch {
        # Prism and vCenter often return 401 before a body; the TLS handshake
        # still populates ServicePoint.Certificate.
    }

    $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
    try {
        $ENDPOINT_REQUEST.GetResponse().Dispose()
    } catch {
        # Same as above: we only need the certificate from the handshake.
    }
    if (-not $ENDPOINT_REQUEST.ServicePoint.Certificate) {
        throw "Could not read the TLS certificate from $URL"
    }
    return $ENDPOINT_REQUEST.ServicePoint.Certificate.GetCertHashString()
}

Function Get-AvailableHypPlugins {
    try {
        $plugins = Get-HypHypervisorPlugin -ErrorAction SilentlyContinue
        if ($plugins) {
            return ($plugins | ForEach-Object {
                $label = $_.Name
                if (-not $label) { $label = $_.DisplayName }
                if (-not $label) { $label = $_.PluginId }
                if (-not $label) { $label = $_.Id }
                if ($_.PluginId -and $label -ne $_.PluginId) { "$label ($($_.PluginId))" } else { $label }
            }) -join ", "
        }
    } catch {
    }
    return "none listed"
}

Function Get-DefaultZoneUid {
    try {
        $zone = Get-BrokerZone -ErrorAction Stop | Select-Object -First 1
        if ($zone -and $zone.Uid) { return $zone.Uid }
    } catch {
    }
    try {
        Add-PSSnapin -Name "Citrix.Configuration.Admin.V2" -ErrorAction SilentlyContinue
        $zone = Get-ConfigZone -ErrorAction Stop | Select-Object -First 1
        if ($zone -and $zone.Uid) { return $zone.Uid }
    } catch {
    }
    return $null
}

# CVAD 2603 Nutanix AHV Prism Central connection address is the PC IP.
# Thumbprint is read from the Prism HTTPS endpoint (9440 when no port is given).
Function Get-NutanixPcAddress {
    param([Parameter(Mandatory = $true)][string]$HostAddress)

    $trimmed = $HostAddress.Trim()
    $withoutScheme = $trimmed -replace '^https?://', ''
    $withoutPath = $withoutScheme -replace '/.*$', ''
    $ipOrHost = $withoutPath -replace ':\d+$', ''
    $thumbUrl = if ($withoutPath -match ':\d+$') { "https://$withoutPath" } else { "https://${ipOrHost}:9440" }
    return @{
        hypervisor = $ipOrHost
        thumbprint_url = $thumbUrl
    }
}

$params = Parse-Args $args -supports_check_mode $false

$name = Get-AnsibleParam $params "name" -type "str" -FailIfEmpty $true
$type = Get-AnsibleParam $params "type" -type "str" -Default "vSphere" -ValidateSet "vSphere", "Nutanix"
$hostAddress = Get-AnsibleParam $params "host_address" -type "str" -FailIfEmpty $true
$hostUsername = Get-AnsibleParam $params "host_username" -type "str" -FailIfEmpty $true
$hostPassword = Get-AnsibleParam $params "host_password" -type "str" -FailIfEmpty $true
$hostSSL = Get-AnsibleParam $params "host_ssl" -type "bool" -default $true
$hostDatacenter = Get-AnsibleParam $params "host_datacenter" -type "str" -FailIfEmpty $false
$hostCompute = Get-AnsibleParam $params "host_compute" -type "str" -FailIfEmpty $false
$hostCluster = Get-AnsibleParam $params "host_cluster" -type "str" -FailIfEmpty $false
$hostNetwork = Get-AnsibleParam $params "host_network" -type "str" -FailIfEmpty $false
$hostStorage = Get-AnsibleParam $params "host_storage" -type "str" -FailIfEmpty $false
$state = Get-AnsibleParam $params "state" -type "str" -Default "present" -ValidateSet "present", "absent"

$result = @{
    changed = $false
}

try {
    Import-Module Citrix.XenDesktop.Admin
    Add-PSSnapin -Name "Citrix.Broker.Admin.V2","Citrix.Host.Admin.V2"
} catch {
    Fail-Json $result "Failed to import the required PowerShell module. Error: $($_)"
}

if ($state -eq "absent") {

    $cInf = Get-ChildItem XDHyp:\HostingUnits | Where-Object {$_.HostingUnitName -eq "$name Resource"}
    if ($cInf) {
        try {
            Remove-Item -Path "XDHyp:\HostingUnits\$($cInf.HostingUnitName)" -Recurse -Force -Confirm:$false
            $result.changed = $true
        } catch {
            Fail-Json $result "Failed removing the hosting unit. Error: $($_)"
        }
    }

    $cConn = Get-ChildItem -Path XDHyp:\Connections | Where-Object {$_.HypervisorConnectionName -eq $name}
    if ($cConn) {
        try {
            Remove-Item -Path "XDHyp:\Connections\$($cConn.HypervisorConnectionName)" -Recurse -Force -Confirm:$false
            $result.changed = $true
        } catch {
            Fail-Json $result "Failed removing the hosting connection. Error: $($_)"
        }
    }

} else {

    $typeNorm = $type.ToLowerInvariant()
    $pluginId = $null
    $hType = $null
    if ($typeNorm -eq "vsphere") {
        $hType = "VCenter"
        $hAddress = "https://$($HostAddress)/sdk"
    } elseif ($typeNorm -eq "nutanix") {
        # Citrix Virtual Apps and Desktops 2603: Nutanix AHV Prism Central.
        # https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/install-configure/connections/connection-nutanix.html
        $hType = "Custom"
        $pluginId = "AcropolisHypervisorPCFactory"
        $pcAddress = Get-NutanixPcAddress -HostAddress $HostAddress
        $hAddress = $pcAddress.hypervisor
        $thumbprintUrl = $pcAddress.thumbprint_url
    } elseif ($typeNorm -eq "xenserver") {
        $hType = "XenServer"
        $hAddress = "https://$($HostAddress)"
    }

    $tumbprint = $null
    if ($hostSSL -eq $false) {
        $hAddress = $hAddress.Replace("https://","http://")
    } elseif ($typeNorm -eq "nutanix") {
        try {
            $tumbprint = Get-SSLThumbprint -URL $thumbprintUrl
        } catch {
            Fail-Json $result "Failed reading the TLS thumbprint from $thumbprintUrl. Error: $($_)"
        }
    } elseif ($hAddress -like "https://*") {
        try {
            $tumbprint = Get-SSLThumbprint -URL $hAddress
        } catch {
            Fail-Json $result "Failed reading the TLS thumbprint from $hAddress. Error: $($_)"
        }
    }

    $cConn = Get-ChildItem -Path XDHyp:\Connections | Where-Object {$_.HypervisorConnectionName -eq $name}
    if (!$cConn) {
        try {
            if ($typeNorm -eq "nutanix") {
                $connectionPath = "XDHyp:\Connections\$name"
                $securePass = ConvertTo-SecureString -String $hostPassword -AsPlainText -Force
                $newItem = @{
                    Path               = @($connectionPath)
                    ConnectionType     = $hType
                    HypervisorAddress  = @($hAddress)
                    Persist            = $true
                    PluginId           = $pluginId
                    Scope              = @()
                    SecurePassword     = $securePass
                    UserName           = $hostUsername
                }
                if ($tumbprint) {
                    $newItem.SSLThumbprint = @($tumbprint)
                }
                $zoneUid = Get-DefaultZoneUid
                if ($zoneUid) {
                    $newItem.ZoneUid = $zoneUid
                }
                $hConn = New-Item @newItem
            } elseif ($pluginId) {
                $hConn = New-Item -Path XDHyp:\Connections -Name $name -HypervisorAddress $hAddress -SSLThumbprint $tumbprint -UserName $HostUserName -Password $HostPassword -ConnectionType $hType -PluginId $pluginId -Persist
            } else {
                $hConn = New-Item -Path XDHyp:\Connections -Name $name -HypervisorAddress $hAddress -SSLThumbprint $tumbprint -UserName $HostUserName -Password $HostPassword -ConnectionType $hType -Persist
            }
            New-BrokerHypervisorConnection -HypHypervisorConnectionUid $hConn.HypervisorConnectionUid | Out-Null
            $result.changed = $true
        } catch {
            Fail-Json $result "Failed creating the $type hosting connection to $hAddress. Plugins: $(Get-AvailableHypPlugins). Error: $($_)"
        }
    }

    if ($typeNorm -eq "nutanix") {
        # 2603: cluster and network are chosen when the machine catalog is
        # created. The hosting unit is only a named container under the PC connection.
        $connectionPath = "XDHyp:\Connections\$name"
        $hostUnitName = "$name Resource"
        $cInf = Get-ChildItem XDHyp:\HostingUnits | Where-Object {$_.HostingUnitName -eq $hostUnitName}
        if (!$cInf) {
            try {
                New-Item -Path @("XDHyp:\HostingUnits\$hostUnitName") -RootPath $connectionPath -HypervisorConnectionName $name -CustomProperties "" -NetworkPath @() -StoragePath @()
                $result.changed = $true
            } catch {
                Fail-Json $result "Failed creating the Nutanix hosting unit '$hostUnitName'. Error: $($_)"
            }
        }
        Exit-Json $result
    } elseif ($hostCluster) {
        $hostSpecificSuffix = "$hostDatacenter.datacenter\$hostCluster.cluster"
        $hRootPath = "XDHyp:\Connections\$($name)\$($hostSpecificSuffix)"
    } elseif ($hostCompute) {
        $hostSpecificSuffix = "$hostDatacenter.datacenter\$hostCompute.computeresource"
        $hRootPath = "XDHyp:\Connections\$($name)\$($hostSpecificSuffix)"
    } elseif ($type -eq "XenServer") {
        $hRootPath = "XDHyp:\Connections\$($name)\"
    } else {
        $hRootPath = "XDHyp:\Connections\$($name)"
    }

    if (-not $hostStorage -or -not $hostNetwork) {
        Fail-Json $result "host_storage and host_network are required for $type hosting units."
    }

    $storage = Get-ChildItem -Path $hRootPath | Where-Object {$_.Name -eq $hostStorage -or $_.Name -like "$hostStorage.*"}
    if ($storage) {
        $storagePath = $storage.FullPath
    } else {
        $available = (Get-ChildItem -Path $hRootPath | ForEach-Object { $_.Name }) -join ", "
        Fail-Json $result "Storage with name $($hostStorage) not found under $hRootPath. Available: $available"
    }

    $network = Get-ChildItem -Path $hRootPath | Where-Object {$_.Name -eq $hostNetwork -or $_.Name -like "$hostNetwork.*"}
    if ($network) {
        $networkPath = $network.FullPath
    } else {
        $available = (Get-ChildItem -Path $hRootPath | ForEach-Object { $_.Name }) -join ", "
        Fail-Json $result "Network with name $($hostNetwork) not found under $hRootPath. Available: $available"
    }

    if (-not $networkPath) {
        $networkPath = "$($hRootPath)\$($hostNetwork).network"
    }
    if (-not $storagePath) {
        $storagePath = "$($hRootPath)\$($hostStorage).storage"
    }

    $cInf = Get-ChildItem XDHyp:\HostingUnits | Where-Object {$_.HostingUnitName -eq "$name Resource"}
    if (!$cInf) {
        try {
            New-Item -Path XDHyp:\HostingUnits -Name "$name Resource" -HypervisorConnectionName $name -RootPath $hRootPath -NetworkPath $networkPath -StoragePath $storagePath
            $result.changed = $true
        } catch {
            Fail-Json $result "Path: $storagePath, Network: $($networkPath) Error: $($_)"
        }
    }
}

Exit-Json $result
