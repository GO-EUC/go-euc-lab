#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2

$params = Parse-Args $args -supports_check_mode $false

# $check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

# $debug_level = Get-AnsibleParam -obj $params -name "_ansible_verbosity" -type "int"
# $debug = $debug_level -gt 2

$licenseServer = Get-AnsibleParam $params "lic_server" -type "str" -Default "localhost"
$licenseServerPort = Get-AnsibleParam $params "lic_port" -type "int" -Default 27000
$licensingModel = Get-AnsibleParam $params "lic_model" -type "str" -Default "UserDevice" -ValidateSet "UserDevice", "Concurrent"
$productCode = Get-AnsibleParam $params "lic_product_code" -type "str" -Default "XDT" -ValidateSet "XDT", "MSP"
$productEdition = Get-AnsibleParam $params "lic_product_edition" -type "str" -Default "PLT" -ValidateSet "STD", "ENT", "PLT"
$state = Get-AnsibleParam $params "state" -type "str" -Default "present"

$result = @{
    changed = $false
}

try {
    Import-Module Citrix.XenDesktop.Admin
} catch {
    Fail-Json $result "Failed to import the required PowerShell module. Error: $($_)"
}

if ($state -eq "absent") {

} else {
    $siteConfig = Get-ConfigSite -AdminAddress $env:ComputerName

    if ($siteConfig.LicenseServerName -ne $licenseServer -or $siteConfig.LicenseServerPort -ne $licenseServerPort) {
        try {
            Set-XDLicensing -AdminAddress $env:ComputerName -LicenseServerAddress $licenseServer -LicenseServerPort $licenseServerPort -Force | Out-Null
            $result.changed = $true
        } catch {
            Fail-Json $result "An error occurred trying to configure the license server, $($licenseServer). Error: $($_)"
        }

        try {
            $metaData = $siteConfig.MetadataMap
            if ($metaData.ContainsKey("CertificateHash")) {
                $cert = (Get-LicCertificate -AdminAddress "https://$($LicenseServer):8083").CertHash

                if ($metaData.CertificateHash -ne $cert) {
                    Set-ConfigSiteMetadata -AdminAddress $ComputerName -Name 'CertificateHash' -Value $cert | Out-Null
                }
            }
        }
        catch {
            Fail-Json $result "An error occurred trying to confirm the certificate hash from server, $($licenseServer). Error: $($_)"
        }
    }

    if ($siteConfig.LicensingModel -ne $licensingModel -or $siteConfig.ProductCode -ne $productCode -or $siteConfig.ProductEdition -ne $productEdition) {
        try {
            Set-ConfigSite  -AdminAddress $env:ComputerName -LicensingModel $licensingModel -ProductCode $productCode -ProductEdition $productEdition | Out-Null
            $result.changed = $true
        } catch {
            Fail-Json $result "An error occurred trying to update the site config of the license server, $($licenseServer). Error: $($_)"
        }
    }
}

Exit-Json $result