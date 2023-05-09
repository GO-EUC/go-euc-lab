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

    # Need to connect using simple GET operation for this to work
    Invoke-RestMethod -Uri $URL -Method Get | Out-Null

    $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
    $SSL_THUMBPRINT = $ENDPOINT_REQUEST.ServicePoint.Certificate.GetCertHashString()

    return $SSL_THUMBPRINT
}

$params = Parse-Args $args -supports_check_mode $false

$name = Get-AnsibleParam $params "name" -type "str" -FailIfEmpty $true
$type = Get-AnsibleParam $params "type" -type "str" -FailIfEmpty $true -Default "vSphere" -ValidateSet "vSphere"
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

    $hType = $null
    if ($type -eq "vsphere") {
        $hType = "VCenter"
        $hAddress = "https://$($HostAddress)/sdk"
    } elseif ($type -eq "xenserver") {
        $hType = "XenServer"
        $hAddress = "https://$($HostAddress)"
    }

    if ($hostSSL -eq $false) {
        $hAddress = $hAddress.Replace("https://","http://")
    } else {
        $tumbprint = Get-SSLThumbprint -URL "https://$($HostAddress)"
    }

    $cConn = Get-ChildItem -Path XDHyp:\Connections | Where-Object {$_.HypervisorConnectionName -eq $name}
    if (!$cConn) {
        $hConn = New-Item -Path XDHyp:\Connections -Name $name -HypervisorAddress $hAddress -SSLThumbprint $tumbprint -UserName $HostUserName -Password $HostPassword -ConnectionType $hType -Persist
        New-BrokerHypervisorConnection -HypHypervisorConnectionUid $hConn.HypervisorConnectionUid | Out-Null
        $result.changed = $true
    }

    if ($hostCluster) {
        $hostSpecificSuffix = "$hostDatacenter.datacenter\$hostCluster.cluster"
    } elseif ($hostCompute) {
        $hostSpecificSuffix = "$hostDatacenter.datacenter\$hostCompute.computeresource"
    } elseif ($type -eq "XenServer") {
        $hostSpecificSuffix = "\"
    }

    $hRootPath = "XDHyp:\Connections\$($name)\$($hostSpecificSuffix)"

    $storage = Get-ChildItem -Path $hRootPath | Where-Object {$_.Name -eq $hostStorage}
    if ($storage) {
        $storagePath = $storage.FullPath
    } else {
        Fail-Json $result "Storage with name $($hostStorage) not found."
    }

    $network = Get-ChildItem -Path $hRootPath | Where-Object {$_.Name -eq $hostNetwork}
    if ($network) {
        $networkPath = $network.FullPath
    } else {
        Fail-Json $result "Network with namae $($hostNetwork) not found."
    }

    $networkPath = "$($hRootPath)\$($hostNetwork).network"
    $storagePath = "$($hRootPath)\$($hostStorage).storage"
    # if ($pvDStorageName -ne "") {
    #     $pvdStoragePath = "$($hRootPath)\$($PvDStorageName).storage"
    # } else {
    #     $pvdStoragePath = "$($hRootPath)\$($hostStorage).storage"
    # }
    
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