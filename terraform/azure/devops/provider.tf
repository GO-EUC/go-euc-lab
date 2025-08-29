terraform {
  required_version = ">= 1.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = ">=3.0.0"
    }

    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}


provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/${var.devops_orgname}"
  personal_access_token = var.devops_token
}
