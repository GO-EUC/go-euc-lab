resource "azurerm_virtual_network" "AzurevNet" {
  name          = "vnet-infra-${local.environment_abbreviations[terraform.workspace]}"
  address_space = [local.infra_cidr[terraform.workspace]]
  dns_servers   = [cidrhost(local.infra_subnet_cidr[terraform.workspace], 10)]

  location            = azurerm_resource_group.VNet.location
  resource_group_name = azurerm_resource_group.VNet.name
}
