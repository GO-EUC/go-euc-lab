# Azure Init Script for GO-EUC Lab

This script provides Azure-native initialization for the GO-EUC lab infrastructure, utilizing the existing comprehensive Terraform modules and delivery solutions.

## What the Script Does

### 1. Azure Authentication & Setup
- Authenticates using Azure Service Principal
- Sets the correct subscription
- Configures environment variables for Terraform

### 2. Settings Processing
- Loads configuration from `settings-azure.json`
- Validates required settings
- Automatically detects external IP for NSG rules
- Generates `terraform.tfvars` compatible with existing infrastructure

### 3. Terraform Deployment
- Downloads Terraform if not present
- Initializes Terraform with existing modules
- Manages Terraform workspaces for environment isolation
- Deploys the complete infrastructure using existing modules

### 4. Infrastructure Components
The script deploys the existing comprehensive infrastructure:

- **Resource Groups**: Separate RGs for Vault, VNet, Infrastructure, Bastion, Docker, SQL, EUC Workers
- **Networking**: Virtual networks and subnets with service endpoints
- **Key Vault**: Secrets management with proper access policies
- **Azure DevOps**: Project and agent pool configuration
- **Compute Gallery**: Shared image gallery for VM images
- **Container Instances**: For services like Hashicorp Vault
- **Delivery Solutions**: CVADS, AVD, or Horizon Cloud based on configuration

## Prerequisites

1. **Azure Service Principal** with appropriate permissions:
   - Contributor role on subscription
   - Azure DevOps permissions

2. **Azure CLI** installed and configured

3. **PowerShell** (Windows, macOS, or Linux)

4. **Settings file** (`settings-azure.json`) with required configuration

## Settings Configuration

Create `settings-azure.json` with the following structure:

```json
{
    "repo_root": "/path/to/GO-EUC-LAB",
    "azure": {
        "subscription_id": "your-subscription-id",
        "tenant_id": "your-tenant-id",
        "client_id": "your-service-principal-client-id",
        "client_secret": "your-service-principal-client-secret",
        "region": "East US"
    },
    "devops": {
        "org_name": "your-azure-devops-org",
        "project_name": "your-project-name",
        "token": "your-azure-devops-pat",
        "pool_name": "Azure Pipelines",
        "agents": 3
    },
    "delivery": "cvads",
    "environment": "default"
}
```

### Delivery Options
- `"cvads"` - Citrix Virtual Apps and Desktops Service
- `"avd"` - Azure Virtual Desktop
- `"horizonc"` - VMware Horizon Cloud
- `"none"` - No delivery solution

### Environment Options
- `"default"` - Default environment (10.100.0.0/16)
- `"cards"` - Cards environment (10.200.0.0/16)
- `"flowers"` - Flowers environment (10.220.0.0/16)

## Usage

### Basic Usage
```powershell
./init-azure.ps1
```

### With Custom Settings
```powershell
./init-azure.ps1 -SettingsFile "my-settings.json"
```

### With External IP
```powershell
./init-azure.ps1 -ExternalIP "203.0.113.1"
```

## Key Differences from vSphere

### Azure-Native Services
- **Azure Container Instances** instead of Docker containers on Ubuntu VMs
- **Azure Key Vault** instead of Hashicorp Vault
- **Azure DevOps** hosted agents instead of self-hosted agents
- **Azure Marketplace Images** instead of custom Packer images

### Modular Infrastructure
- **Reusable Terraform modules** for Windows VMs, AVD, etc.
- **Environment isolation** via Terraform workspaces
- **Multi-platform EUC support** (Citrix, AVD, Horizon)
- **Production-ready architecture** with proper resource separation

### Benefits
- **Cost effective**: No need for Ubuntu VMs to host containers
- **Scalable**: Azure-native services scale automatically
- **Secure**: Azure Key Vault with managed identities
- **Maintainable**: Modular Terraform with clear separation of concerns

## Output

The script will create:

1. **Resource Groups** with naming pattern: `rg-golab-{environment}-{purpose}`
2. **Virtual Network** with subnets for different purposes
3. **Key Vault** with secrets for admin passwords
4. **Azure DevOps** project and agent pool
5. **Container Instances** for services
6. **Delivery infrastructure** based on selected platform

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Service Principal credentials
   - Ensure SPN has Contributor role

2. **Terraform Init Failures**
   - Check Azure CLI authentication
   - Verify subscription access

3. **Workspace Issues**
   - Use `terraform workspace list` to see available workspaces
   - Use `terraform workspace select <name>` to switch workspaces

4. **Resource Group Conflicts**
   - Each environment uses separate resource groups
   - Change environment in settings to create new deployment

### Getting Help

- Check Terraform outputs for resource information
- Review Azure portal for deployed resources
- Check Azure DevOps for project and agent pool status

