param (
    # Repository root
    [Parameter(Mandatory = $true)]
    [string]
    $RepoRoot,

    # Settings Json
    [Parameter(Mandatory = $true)]
    [string]
    $SettingsFile,

    # Azure DevOps PAT Token
    [Parameter(Mandatory = $true)]
    [string]
    $AdoPat,

    # ESXi host password in string format
    [Parameter(Mandatory = $true)]
    [securestring]
    $ESXPassword
)

Write-Output "$(Get-Date): Collecting settings"
# Collecting settings JSON
$settingsCheck = Test-Path -Path $SettingsFile
if ($settingsCheck -eq $false) {
    Write-Error "Cannot find the required settings JSON file, please consult the documentation."
} else {
    $settings = Get-Content -Path $SettingsFile -Raw | ConvertFrom-Json
}

Write-Output "$(Get-Date): Clear the SSH trusted hosts"
Get-SSHTrustedHost | Remove-SSHTrustedHost | Out-Null

# Trim the RepoRoot
$RepoRoot = $RepoRoot.Trim("\")

Write-Output "$(Get-Date): Checking for the Posh SSH Module"
# Check if the Posh-SSH module is installed
if (!(Get-Module -ListAvailable -Name "Posh-SSH")) {
    Install-Module -Name "Posh-SSH" -Scope CurrentUser -Confirm:$false
} 

Write-Output "$(Get-Date): Downloading and extracting required Hasicorp binaries"
# Download Hashicorp binaries using the Evergreen API from stealthpuppy (Aaron Parker)
$binaries = @()
$binaries += Invoke-RestMethod -Method GET -Uri "https://evergreen-api.stealthpuppy.com/app/HashicorpTerraform"
$binaries += Invoke-RestMethod -Method GET -Uri "https://evergreen-api.stealthpuppy.com/app/HashicorpPacker"
$binaries += Invoke-RestMethod -Method GET -Uri "https://evergreen-api.stealthpuppy.com/app/HashicorpVault"

# Apply filter
$binaries = $binaries | Where-Object {$_.Architecture -eq "x64"}

# Download and extract
foreach ($bin in $binaries) {
    $fileName = $($bin.URI).Substring($($bin.URI).LastIndexOf("/") +1)
    Invoke-RestMethod -Method GET -Uri $($bin.URI) -OutFile "$($ENV:Temp)\$fileName"

    New-Item -Path "$env:TEMP\Hashicorp" -ItemType Directory -Force -Confirm:$false | Out-Null

    Expand-Archive -Path "$($ENV:Temp)\$fileName" -DestinationPath "$env:TEMP\Hashicorp" -Force
}

Write-Output "$(Get-Date): Setting ESX host requirements for Packer"
# Creating ESX credentials
$esxCredentials = New-Object System.Management.Automation.PSCredential ($($settings.esx_username), $ESXPassword)

# Connect to the ESX host
try {
    $esxSession = New-SSHSession -ComputerName $($settings.esx_host_ip) -Credential $esxCredentials -AcceptKey
    $esxSftpSession = New-SFTPSession -ComputerName $($settings.esx_host_ip) -Credential $esxCredentials -AcceptKey

} catch {
    Write-Error "Cannot create the required SSH connection."
}

# Set required Packer setting
Invoke-SSHCommand -SSHSession $esxSession -Command "esxcli system settings advanced set -o /Net/GuestIPHack -i 1" | Out-Null

# Copy over firewall template for VNC and apply
Set-SFTPItem -SFTPSession $esxSftpSession -Path "$($RepoRoot)\init\data\esx\packer.xml" -Destination "/etc/vmware/firewall/" -Force 
Invoke-SSHCommand -SSHSession $esxSession -Command "esxcli network firewall refresh" | Out-Null

# Close SFTP session
$esxSftpSession.Disconnect()

Write-Output "$(Get-Date): Download and extracting OpenSSL for password encryption"
# Download OpenSSL to generate an SHA512 enqrypted password for the Ubuntu installation
$urlOpenSSL = "http://wiki.overbyte.eu/arch/openssl-3.0.7-win64.zip"
Invoke-WebRequest -Uri $urlOpenSSL -OutFile "$($env:TEMP)\openssl-3.0.7-win64.zip"
Expand-Archive -Path "$($env:TEMP)\openssl-3.0.7-win64.zip" -DestinationPath "$($env:TEMP)\OpenSSL\" -Force

# Collect the openssl executable in the Temp location
$exeOpenSSL = (Get-ChildItem -Path "$($env:TEMP)\OpenSSL\" -Recurse -Filter "openssl.exe").FullName

# Generate and encrypt random password for the Ubunut installation
$randomPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789$%&*#'.ToCharArray() | Get-Random -Count 16)

# Use the & as this will allow to capture the output
$encryptPassword = & $exeOpenSSL passwd -6 $randomPassword

# Cleanup the openssl locaiton as this not rquired anymore
Remove-Item -Path "$($env:TEMP)\openssl-3.0.7-win64.zip" -Confirm:$false
Remove-Item -Path "$($env:TEMP)\OpenSSL\" -Recurse -Confirm:$false

Write-Output "$(Get-Date): Building Packer files"
# Create Packer variables
$packer = @{}

$packer.Add("esx_host", $($settings.esx_host_ip))
$packer.Add("esx_username", $($settings.esx_username))
$packer.Add("vm_network_name", $($settings.esx_network))
$packer.Add("network_cidr", $($settings.network_cidr) )
$packer.Add("network_address", $($settings.network_address) )
$packer.Add("network_gateway", $($settings.network_gateway) )
$packer.Add("network_dns", $($settings.network_dns) )
$packer.Add("vm_name", $($settings.docker_name) )
$packer.Add("vm_disk_size", 122880 )
$packer.Add("vm_guest_os_timezone", "CET")
$packer.Add("build_username", $($settings.docker_username))

# Write packer variables to file
New-Item -Path "$($RepoRoot)\packer\vmware\init\packer.pkrvars.hcl" -ItemType File -Force | Out-Null
foreach ($var in $packer.GetEnumerator()) {
    if ($var.value.GetType().Name -eq "string") {
        $value = "`"$($var.Value)`""
    } else {
        $value = $var.value.ToString().ToLower()
    }

    $line = "$($var.Key) = $($value)"
    Add-Content -Path "$($RepoRoot)\packer\vmware\init\packer.pkrvars.hcl" -Value $line
}

# Argument list for init
$packerInit = @{
    FilePath =  "$env:TEMP\Hashicorp\packer.exe"
    ArgumentList = "init $($RepoRoot)\packer\vmware\init"
    WorkingDirectory = "$($RepoRoot)\packer\vmware\init"
}

Write-Output "$(Get-Date): Packer init"
# Start Packer init
Start-Process @packerInit -NoNewWindow -Wait

# Convert back to plain text password for Packer
$unsecureEsxPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($esxPassword))

# Build string for packer build
$buildString = "build "
$buildString += "-var-file=`"$($RepoRoot)\packer\vmware\init\packer.pkrvars.hcl`" "
$buildString += "-var `"esx_password=$unsecureEsxPassword`" "
$buildString += "-var `"build_password=$randomPassword`" "
$buildString += "-var `"build_password_encrypted=$encryptPassword`" . "

Write-Output "$(Get-Date): Packer build"
# Start Packer build
$packerBuild = @{
    FilePath =  "$env:TEMP\Hashicorp\packer.exe"
    ArgumentList = $buildString
    WorkingDirectory = "$($RepoRoot)\packer\vmware\init"
}

Start-Process @packerBuild -NoNewWindow -Wait

Write-Output "$(Get-Date): Starting docker host on ESX host"
# Make sure the VM is started again, as Packer will shutdown the machine
$id = Invoke-SSHCommand -SSHSession $esxSession -Command "vim-cmd vmsvc/getallvms | sed '1d' | awk '{if (`$1 > 0) print `$1`":`"`$2}' | grep $($settings.docker_name) | cut -d `':`' -f1"
Invoke-SSHCommand -SSHSession $esxSession -Command "vim-cmd vmsvc/power.on $($id.Output)" | Out-Null

# Disconnect from the ESX host, as we don't need it anymore
$esxSession.Disconnect()

$dockerIp = $($settings.network_cidr).Substring(0, $($settings.network_cidr).LastIndexOf(".") +1) + $($settings.network_address)
$dockerPort = 22 # default SSH port

$timeout = 120 # based 1 sec sleep this timeout is two minutes
$timeoutCounter = 0

Write-Output "$(Get-Date): Waiting for host to boot"
while ((Test-NetConnection -ComputerName $dockerIp -Port $dockerPort -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded -eq $false) {
    if ($timeout -eq $timeoutCounter) {
        Write-Error "Timeout reached while waiting for the docker host"
    }

    Start-Sleep 1
    $timeoutCounter++
}

Write-Output "$(Get-Date): Connecting to Docker host"
# Restore the ProgressPreference
$ProgressPreference = $currentProgressPreference

# Create docker credentials
$dockerCredentials = New-Object System.Management.Automation.PSCredential($($settings.docker_username), (ConvertTo-SecureString $randomPassword -AsPlainText -Force))

# Connect to the docker host
$dockerSession = New-SSHSession -ComputerName $dockerIp -Credential $dockerCredentials -AcceptKey
$dockerSftpSession = New-SFTPSession -ComputerName $dockerIp -Credential $dockerCredentials -AcceptKey

# Create required dir on the docker host to ensure database is persitent
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo mkdir -p /etc/postgresql" | Out-Null

# Generate a random password for the Postgress database
$postgressPassword = -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789'.ToCharArray() | Get-Random -Count 6)

# Create the docker command line
$postgressCommand = "docker run -d --restart unless-stopped "
$postgressCommand += "-v /etc/postgresql:/var/lib/postgresql/data "
$postgressCommand += "-e POSTGRES_USER=tf "
$postgressCommand += "-e POSTGRES_PASSWORD=$($postgressPassword) "
$postgressCommand += "-e POSTGRES_DB=state "
$postgressCommand += "-p $($dockerIp):5432:5432 "
$postgressCommand += "--name postgres postgres:latest"


Write-Output "$(Get-Date): Starting Docker postgress container"
# Start Postgress container
Invoke-SSHCommand -SSHSession $dockerSession -Command $postgressCommand | Out-Null

# Create required dir on the docker host to ensure vault is persitent
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo mkdir -p /etc/vault/logs" | Out-Null
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo mkdir -p /etc/vault/config" | Out-Null
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo mkdir -p /etc/vault/file" | Out-Null

# Copy over the vault configuration
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo chmod a+rwx /etc/vault/config/" | Out-Null
Set-SFTPItem -SFTPSession $dockerSftpSession -Path "$($RepoRoot)\init\data\vault\config.hcl" -Destination "/etc/vault/config/" -Force

# Create the docker command line
$vaultCommand = "docker run -d --restart unless-stopped "
$vaultCommand += "-v /etc/vault:/vault "
$vaultCommand += "--cap-add=IPC_LOCK "
$vaultCommand += "-p $($dockerIp):8200:8200 "
$vaultCommand += "--name vault vault:latest server"

Write-Output "$(Get-Date): Starting Docker vault container"
# Start Hashicorp Vault container
Invoke-SSHCommand -SSHSession $dockerSession -Command $vaultCommand | Out-Null

Write-Output "$(Get-Date): Init the Hashicorp Vault"
# Set the formatting of vault to json
$env:VAULT_FORMAT = "json"

# Set vault address to the vault
$env:VAULT_ADDR="http://$($dockerIp):8200"

# Collect the vault start
$vaultStatus = & "$env:TEMP\Hashicorp\vault.exe" status | ConvertFrom-Json

# Initialize the vault
if ($vaultStatus.initialized -eq $false) {
    $vaultInit =  & "$env:TEMP\Hashicorp\vault.exe" operator init | ConvertFrom-Json
}

# Recollect the status
$vaultStatus = & "$env:TEMP\Hashicorp\vault.exe" status | ConvertFrom-Json

# Unseal the vault
if ($vaultStatus.sealed -eq $true) {
    $unseal = @()
    for ($i = 0; $i -lt $vaultStatus.t; $i++) {
        $unseal += & "$env:TEMP\Hashicorp\vault.exe" operator unseal $($vaultInit.unseal_keys_b64[$i]) | ConvertFrom-Json
    }
}

# Enable kv vault
& "$env:TEMP\Hashicorp\vault.exe" secrets enable -version=1 -path go kv | Out-Null

# Adding secrets to the vault
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go domain name=$($settings.domain_name)
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go vmware/esx/$($esx_host_name) password=$($unsecureEsxPassword) user=$($settings.esx_username) ip=$($esx_host_ip) name=$($esx_host_name) datastore=$($settings.esx_datastore) network=$($settings.esx_network)
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go vmware/vcsa ip=$($settings.vcsa_ip) name=$($settings.vcsa_name)
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go vmware/network network_cidr=$($settings.network_cidr) network_gateway=$($settings.network_gateway) network_dns=$($settings.network_dns)
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go docker password=$randomPassword user=$($settings.docker_username) ip=$($dockerIp) name=$($settings.docker_name)
& "$env:TEMP\Hashicorp\vault.exe" kv put -mount=go postgress password=$($postgressPassword) user=tf ip=$($dockerIp) ssl=disable

Write-Output "$(Get-Date): Building Terraform variables"
# Create variable file for the Azure DevOps variables
$tfAdoVars = @()
$tfAdoVars += [PSCustomObject]@{
    name = "postgress_user"
    value = "tf"
    is_secret = $false
}

$tfAdoVars += [PSCustomObject]@{
    name = "postgress_password"
    value = $postgressPassword
    is_secret = $true
}

$tfAdoVars += [PSCustomObject]@{
    name = "postgress_address"
    value = $dockerIp
    is_secret = $false
}

$tfAdoVars += [PSCustomObject]@{
    name = "postgress_ssl"
    value = "disable"
    is_secret = $false
}

$vaultCounter = 1
foreach ($vaultKey in $vaultInit.unseal_keys_b64) {
    $tfAdoVars += [PSCustomObject]@{
        name = "vault_unseal_$($vaultCounter)"
        value = $($vaultKey)
        is_secret = $true
    }

    $vaultCounter++
}

$tfAdoVars += [PSCustomObject]@{
    name = "vault_token"
    value = "$($vaultInit.root_token)"
    is_secret = $true
}

$tfAdoVars += [PSCustomObject]@{
    name = "vault_addr"
    value = "http://$($dockerIp):8200"
    is_secret = $false
}

$tfAdoVars = ($tfAdoVars | ConvertTo-Json).Replace(":", " =")
$tfAdoVars = $tfAdoVars.Replace("`"name`"", "name")
$tfAdoVars = $tfAdoVars.Replace("`"value`"", "value")
$tfAdoVars = $tfAdoVars.Replace("`"is_secret`"", "is_secret")

$tfAdoVarsFile = @()
$tfAdoVarsFile += "ado_variables = " + $tfAdoVars

Set-Content -Path "$($RepoRoot)\terraform\devops\terraform.tfvars" -Value $tfAdoVarsFile -Force

# Create splat for terraform
$tfParams = @{
    FilePath = "$env:TEMP\Hashicorp\terraform.exe"
    WorkingDirectory = "$($RepoRoot)\terraform\devops"
}

# Setup the init command with the backend
$terraformBackend = "conn_str=postgres://tf:$($postgressPassword)@$($dockerIp)/state?sslmode=disable"
$tfInit = "init -backend-config=`"$($terraformBackend)`""

$env:TF_VAR_ado_pat=$($AdoPat)
$env:TF_VAR_ado_url=$($settings.ado_url)

# Create plan command
$tfPlan = "plan "
$tfPlan += "-out=plan.tfplan"

# Create apply command
$tfApply  = "apply `"plan.tfplan`""

Write-Output "$(Get-Date): Terraform init"
Start-Process @tfParams -ArgumentList $tfInit -NoNewWindow -Wait
Write-Output "$(Get-Date): Terraform plan"
Start-Process @tfParams -ArgumentList $tfPlan -NoNewWindow -Wait
Write-Output "$(Get-Date): Terraform apply"
Start-Process @tfParams -ArgumentList $tfApply -NoNewWindow -Wait

# Remove the terraform.tfvar file
# Remove-Item -Path "$($RepoRoot)\terraform\devops\terraform.tfvars" -Force -Confirm:$false | Out-Null

# Agent command static
$agentCommandStatic = "docker run -d --restart unless-stopped "
$agentCommandStatic += "-e AZP_URL=$($settings.ado_url) "
$agentCommandStatic += "-e AZP_TOKEN=$($AdoPat) "

Write-Output "$(Get-Date): Starting Azure DevOps Agent containers"
# Start DevOps agents containers with timeout as the download requires some time
for ($i = 0; $i -lt $($settings.ado_agents); $i++) {
    
    # Create the docker command line
    $agentCommand = $agentCommandStatic
    $agentCommand += "-e AZP_AGENT_NAME=agent-$($i + 1) "
    $agentCommand += "-e AZP_POOL=`"GO Pipelines`" "
    $agentCommand += "--name agent$($i + 1) "
    $agentCommand += "goeuc/ado-agent:latest"

    Invoke-SSHCommand -SSHSession $dockerSession -Command $agentCommand -TimeOut 300 | Out-Null
}

Write-Output "$(Get-Date): Copy the software library"
# Copy over the software sources
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo mkdir -p /go" | Out-Null
Invoke-SSHCommand -SSHSession $dockerSession -Command "sudo chmod a+rwx /go" | Out-Null

# Copy over the software repo
Set-SFTPItem -SFTPSession $dockerSftpSession -Path "$($settings.software_store)\*" -Destination "/go/" -Force

# Disconnect the sessions
$dockerSession.Disconnect()
$dockerSftpSession.Disconnect()

Write-Output "$(Get-Date): Done!"
Write-Output "$(Get-Date): Docker password: $randomPassword"
