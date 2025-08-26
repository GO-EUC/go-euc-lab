terraform {

  required_version = ">= 1.2" 

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.117"
    }

    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=1.11"
    }

    random = {
      source = "hashicorp/random"
      version = "~>3.7"
    }
  }

      backend "azurerm" {
    resource_group_name  = "rg-golab-default-tfstate"
    storage_account_name = "golabtfstatedefault518"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/${var.devops_orgname}"
  personal_access_token = var.devops_token
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }

  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}











