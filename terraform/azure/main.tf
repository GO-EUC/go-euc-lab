terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.9"

    }

    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
  }



  backend "azurerm" {
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