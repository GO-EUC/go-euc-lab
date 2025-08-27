param (
    # Settings Json
    [Parameter(Mandatory = $false)]
    [string]
    $SettingsFile = "settings.json",

    # Azure DevOps PAT Token
    [Parameter(Mandatory = $true)]
    [string]
    $AdoPat,

    # GitHub PAT Token
    [Parameter(Mandatory = $true)]
    [string]
    $GitHubPat,

    # Azure client secret in string format
    [Parameter(Mandatory = $true)]
    [string]
    $ClientSecret,

    # External IP address for NSG rules (optional)
    [Parameter(Mandatory = $false)]
    [string]
    $ExternalIP
)

# Set error action
$ErrorActionPreference = 'Stop'

Write-Output "$(Get-Date): Starting Azure initialization for GO-EUC Lab"

# Function to detect external IP
function Get-ExternalIP {
    try {
        $response = Invoke-RestMethod -Uri "https://ipinfo.io/ip" -TimeoutSec 10
        return $response.Trim()
    } catch {
        try {
            $response = Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 10
            return $response.Trim()
        } catch {
            Write-Warning "Could not detect external IP address automatically"
            return $null
        }
    }
}

# Load settings
if (!(Test-Path $SettingsFile)) {
    Write-Error "Settings file $SettingsFile not found"
    exit 1
}

$settings = Get-Content -Path $SettingsFile -Raw | ConvertFrom-Json

# Validate required settings
$requiredSettings = @(
    "azure.subscription_id",
    "azure.tenant_id",
    "azure.client_id",
    "azure.client_secret",
    "azure.region",
    "devops.org_name",
    "devops.project_name",
    "devops.token",
    "devops.pool_name"
)

foreach ($setting in $requiredSettings) {
    $path = $setting.Split('.')
    $value = $settings
    foreach ($key in $path) {
        if ($value.PSObject.Properties.Name -contains $key) {
            $value = $value.$key
        } else {
            Write-Error "Required setting '$setting' not found in $SettingsFile"
            exit 1
        }
    }
}

# Handle external IP
if (!($ExternalIP)) {
    $autoExternalIP = Get-ExternalIP
    if (!($autoExternalIP)) {
        Write-Warning "No external IP address was specified and it could not be automatically detected."
        Write-Warning "NSG rules will use default values."
    } else {
        $ExternalIP = $autoExternalIP
        Write-Output "$(Get-Date): Detected external IP: $ExternalIP"
    }
} else {
    Write-Output "$(Get-Date): Using provided external IP: $ExternalIP"
}

# Set repo root
$RepoRoot = $settings.repo_root.TrimEnd("\").TrimEnd("/")
$TerraformDir = Join-Path $RepoRoot "terraform" "azure"

Write-Output "$(Get-Date): Using Terraform directory: $TerraformDir"

# Authenticate to Azure
Write-Output "$(Get-Date): Authenticating to Azure using Service Principal"
az login --service-principal --username $($settings.azure.client_id) --password $($settings.azure.client_secret) --tenant $($settings.azure.tenant_id)
az account set --subscription $($settings.azure.subscription_id)

# Set environment variables for Terraform
$env:ARM_CLIENT_ID = $settings.azure.client_id
$env:ARM_CLIENT_SECRET = $settings.azure.client_secret
$env:ARM_SUBSCRIPTION_ID = $settings.azure.subscription_id
$env:ARM_TENANT_ID = $settings.azure.tenant_id

# Create terraform.tfvars from settings
Write-Output "$(Get-Date): Creating Terraform variables file"
$tfVars = @{
    azure_subscription_id = $settings.azure.subscription_id
    azure_tenant_id       = $settings.azure.tenant_id
    azure_client_id       = $settings.azure.client_id
    azure_client_secret   = $settings.azure.client_secret
    azure_region          = $settings.azure.region
    devops_orgname        = $settings.devops.org_name
    devops_project        = $settings.devops.project_name
    devops_token          = $settings.devops.token
    devops_pool           = $settings.devops.pool_name
    devops_agents         = $settings.devops.agents
    delivery              = $settings.delivery
}

# Note: external_ip is not used in the existing Terraform configuration
# The existing infrastructure uses hardcoded NSG rules

# Convert to HCL format
$tfVarsContent = @()
foreach ($key in $tfVars.Keys) {
    $value = $tfVars[$key]
    if ($value -is [string]) {
        $tfVarsContent += "$key = `"$value`""
    } else {
        $tfVarsContent += "$key = $value"
    }
}

$tfVarsPath = Join-Path $TerraformDir "terraform.tfvars"
$tfVarsContent -join "`n" | Set-Content -Path $tfVarsPath -Force
Write-Output "$(Get-Date): Terraform variables written to $tfVarsPath"

# Download Terraform if not present
$terraformCommand = if ($IsWindows) { "terraform.exe" } else { "terraform" }
if (!(Get-Command $terraformCommand -ErrorAction SilentlyContinue)) {
    Write-Output "$(Get-Date): Downloading Terraform"

    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }

    $terraformVersion = "1.5.7"
    $downloadUrl = "https://releases.hashicorp.com/terraform/$terraformVersion/terraform_${terraformVersion}_${os}_${arch}.zip"
    $tempDir = Join-Path $env:TEMP "terraform"
    $zipPath = Join-Path $tempDir "terraform.zip"

    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        $terraformPath = Join-Path $tempDir "terraform"
        if ($IsWindows) { $terraformPath += ".exe" }

        # Add to PATH for current session
        $env:PATH = "$tempDir;$env:PATH"
        $terraformCommand = if ($IsWindows) { "terraform.exe" } else { "terraform" }

        Write-Output "$(Get-Date): Terraform downloaded and available as '$terraformCommand'"
    } catch {
        Write-Error "Failed to download Terraform: $_"
        exit 1
    }
}

# Function to set up Azure Storage for Terraform backend
function Setup-TerraformBackend {
    param (
        [Parameter(Mandatory = $true)]
        [object]$settings
    )

    Write-Output "$(Get-Date): Setting up Terraform backend storage"

    # Create a storage account for Terraform state
    $storageAccountName = "golabtfstate$($settings.environment)$(Get-Random -Minimum 100 -Maximum 999)"
    $resourceGroupName = "rg-golab-$($settings.environment)-tfstate"
    $containerName = "terraform-state"

    Write-Output "$(Get-Date): Creating resource group: $resourceGroupName"
    az group create --name $resourceGroupName --location $settings.azure.region

    Write-Output "$(Get-Date): Creating storage account: $storageAccountName"
    Write-Output "$(Get-Date): Storage account will be created in resource group: $resourceGroupName"
    az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $settings.azure.region --sku Standard_LRS --encryption-services blob

    Write-Output "$(Get-Date): Creating blob container"
    az storage container create --name $containerName --account-name $storageAccountName

    # Get storage account key
    $storageKey = az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query '[0].value' -o tsv

    # Assign Storage Blob Data Contributor role to the Service Principal
    Write-Output "$(Get-Date): Assigning storage permissions to Service Principal"
    $scope = "/subscriptions/$($settings.azure.subscription_id)/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    az role assignment create --assignee $settings.azure.client_id --role "Storage Blob Data Contributor" --scope $scope

    # Update backend configuration in main.tf
    $mainTfPath = Join-Path $TerraformDir "main.tf"
    $backendTfPath = Join-Path $TerraformDir "backend.tf"

    # Remove any existing backend.tf file to avoid conflicts
    if (Test-Path $backendTfPath) {
        Remove-Item $backendTfPath -Force
        Write-Output "$(Get-Date): Removed existing backend.tf to avoid conflicts"
    }

    $mainTfContent = Get-Content -Path $mainTfPath -Raw

    # Replace the empty backend block with the configured one
    $newBackendBlock = @"
  backend "azurerm" {
    resource_group_name  = "$resourceGroupName"
    storage_account_name = "$storageAccountName"
    container_name       = "$containerName"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
"@

    # Update provider versions to match locked versions
    $mainTfContent = $mainTfContent -replace 'version = "~>2.9"', 'version = "~>3.117"'
    $mainTfContent = $mainTfContent -replace 'version = ">=0.1.0"', 'version = ">=1.11"'
    $mainTfContent = $mainTfContent -replace 'version = "~>3.4"', 'version = "~>3.7"'

    # Replace the existing backend block with the new configuration
    $backendPattern = 'backend "azurerm" \{[^}]*\}'
    $updatedContent = $mainTfContent -replace $backendPattern, $newBackendBlock
    $updatedContent | Set-Content -Path $mainTfPath -Force
    Write-Output "$(Get-Date): Backend configuration updated in $mainTfPath"

    return @{
        ResourceGroup = $resourceGroupName
        StorageAccount = $storageAccountName
        Container = $containerName
    }
}

# Change to Terraform directory
Push-Location $TerraformDir

try {
    # Set up Terraform backend storage
    $backendInfo = Setup-TerraformBackend -settings $settings

    # Set the Terraform workspace based on environment
    $workspace = $settings.environment
    Write-Output "$(Get-Date): Using Terraform workspace: $workspace"

    # Initialize Terraform
    Write-Output "$(Get-Date): Initializing Terraform"
    & $terraformCommand init -reconfigure
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed with exit code $LASTEXITCODE"
    }

    # Select or create workspace
    Write-Output "$(Get-Date): Selecting Terraform workspace: $workspace"
    & $terraformCommand workspace select $workspace
    if ($LASTEXITCODE -ne 0) {
        Write-Output "$(Get-Date): Creating new workspace: $workspace"
        & $terraformCommand workspace new $workspace
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Terraform workspace with exit code $LASTEXITCODE"
        }
    }

    # Plan deployment
    Write-Output "$(Get-Date): Planning Terraform deployment"
    & $terraformCommand plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed with exit code $LASTEXITCODE"
    }

    # Apply deployment
    Write-Output "$(Get-Date): Applying Terraform deployment"
    & $terraformCommand apply -auto-approve tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed with exit code $LASTEXITCODE"
    }

    Write-Output "$(Get-Date): Terraform deployment completed successfully"

    # Show outputs
    Write-Output "$(Get-Date): Deployment outputs:"
    & $terraformCommand output

} catch {
    Write-Error "Terraform deployment failed: $_"
    exit 1
} finally {
    Pop-Location
}

Write-Output "$(Get-Date): Azure initialization completed successfully!"