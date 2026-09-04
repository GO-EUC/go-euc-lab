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
                if ($_.PluginId) { "$($_.Name) ($($_.PluginId))" } else { $_.Name }
            }) -join ", "
        }
    } catch {
    }
    return "none listed"
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
$hostNetwork = Get-AnsibleParam $params "host_network" -type "str" -FailIfEmpty $true
$hostStorage = Get-AnsibleParam $params "host_storage" -type "str" -FailIfEmpty $true
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
        $hType = "Custom"
        $pluginId = "AcropolisFactory"
        if ($HostAddress -match '^https?://') {
            $hAddress = $HostAddress
        } else {
            $hAddress = "https://$($HostAddress):9440"
        }
    } elseif ($typeNorm -eq "xenserver") {
        $hType = "XenServer"
        $hAddress = "https://$($HostAddress)"
    }

    $tumbprint = $null
    if ($hostSSL -eq $false) {
        $hAddress = $hAddress.Replace("https://","http://")
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
            if ($pluginId) {
                try {
                    $hConn = New-Item -Path XDHyp:\Connections -Name $name -HypervisorAddress $hAddress -SSLThumbprint $tumbprint -UserName $HostUserName -Password $HostPassword -ConnectionType $hType -PluginId $pluginId -Persist
                } catch {
                    $hConn = New-Item -Path XDHyp:\Connections -Name $name -HypervisorAddress $hAddress -SSLThumbprint $tumbprint -UserName $HostUserName -Password $HostPassword -ConnectionType $hType -HypervisorPluginId $pluginId -Persist
                }
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
        $connectionRoot = "XDHyp:\Connections\$name"
        $children = @(Get-ChildItem -Path $connectionRoot -ErrorAction SilentlyContinue)
        $clusterItem = $children | Where-Object {
            $_.Name -eq $hostCluster -or
            $_.Name -like "$hostCluster.*" -or
            $_.PSChildName -eq $hostCluster
        } | Select-Object -First 1
        if (-not $clusterItem -and $children.Count -eq 1) {
            $clusterItem = $children[0]
        }
        if (-not $clusterItem) {
            $available = ($children | ForEach-Object { $_.Name }) -join ", "
            Fail-Json $result "Nutanix cluster '$hostCluster' not found under $connectionRoot. Available: $available"
        }
        $hRootPath = $clusterItem.FullPath
        if (-not $hRootPath) {
            $hRootPath = "$connectionRoot\$($clusterItem.Name)"
        }
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
