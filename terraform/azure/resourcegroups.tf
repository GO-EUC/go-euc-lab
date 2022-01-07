#Resource groups used for deployment

resource "azurerm_resource_group" "InfraBackend" {
    name        = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-infra"
    location    = local.azure_location
}

resource "azurerm_resource_group" "Bastion" {
    name        = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-bastion"
    location    = local.azure_location
}

resource "azurerm_resource_group" "Docker" {
    name        = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-docker"
    location    = local.azure_location
}

resource "azurerm_resource_group" "Loadgen" {
    name        = "rg-${local.deploymentname}-${local.environment_abbreviations[terraform.workspace]}-loadgen"
    location    = local.azure_location
}
