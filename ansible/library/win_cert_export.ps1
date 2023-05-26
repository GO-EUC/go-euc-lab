#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2

$params = Parse-Args $args -supports_check_mode $false

$computerName = Get-AnsibleParam $params "host" -type "str" -FailIfEmpty $true
$port = Get-AnsibleParam $params "port" -type "int" -Default 443

$result = @{
    changed = $false
}

$Certificate = $null
$TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
try {

    $TcpClient.Connect($ComputerName, $Port)
    $TcpStream = $TcpClient.GetStream()

    $Callback = { 
        param(
            $sender, 
            $cert, 
            $chain, 
            $errors
        ) 
        return $true 
    }

    $SslStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList @($TcpStream, $true, $Callback)
    try {

        $SslStream.AuthenticateAsClient('')
        $Certificate = $SslStream.RemoteCertificate

    } finally {
        $SslStream.Dispose()
    }

} finally {
    $TcpClient.Dispose()
}

if ($Certificate) {
    if ($Certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
        $Certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $Certificate
    }

    $certString = [System.Convert]::ToBase64String($Certificate.RawData)

    $certOutput = "-----BEGIN CERTIFICATE-----`n"
    $charCounter = 0

    for ($i = 0; $i -lt $certString.Length; $i++) {
        if ($charCounter -eq 64) {
            $certOutput += "`n"
            $certOutput += $certString[$i]
            $charCounter = 0
        } else {
            $certOutput += $certString[$i]
        }
        $charCounter++
    }

    $certOutput += "`n"
    $certOutput += "-----END CERTIFICATE-----`n"

    $result.changed = $true
    $result.cert = $certOutput
    $result.cert_string = "-----BEGIN CERTIFICATE-----`n" + $certString + "`n-----END CERTIFICATE-----"


    Write-Output $Certificate
}

Exit-Json $result