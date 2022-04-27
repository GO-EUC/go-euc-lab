#Resource groups used for deployment

resource "azurerm_resource_group" "Vault" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-vault"
  location = var.azure_region
}

resource "azurerm_resource_group" "VNet" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-vnet"
  location = var.azure_region
}

resource "azurerm_resource_group" "InfraBackend" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-infra"
  location = var.azure_region
}

resource "azurerm_resource_group" "Bastion" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-bastion"
  location = var.azure_region
}

resource "azurerm_resource_group" "Docker" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-docker"
  location = var.azure_region
}

resource "azurerm_resource_group" "SQL" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-sql"
  location = var.azure_region
}

resource "azurerm_resource_group" "EUCWorkers" {
  name     = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-workers"
  location = var.azure_region
}