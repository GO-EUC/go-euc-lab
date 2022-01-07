#vNet with peerings is imported in "Azure_vnet_import.tf"

resource "azurerm_subnet" "backend" {
  name                                           = "sn-infra-${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name                            = azurerm_resource_group.VNet.name
  virtual_network_name                           = azurerm_virtual_network.AzurevNet.name
  address_prefixes                               = [local.infra_subnet_cidr[terraform.workspace]]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "bastion" {
  name                                           = "AzureBastionSubnet"
  resource_group_name                            = azurerm_resource_group.VNet.name
  virtual_network_name                           = azurerm_virtual_network.AzurevNet.name
  address_prefixes                               = [local.bastion_subnet_cidr[terraform.workspace]]
  enforce_private_link_endpoint_network_policies = true
}