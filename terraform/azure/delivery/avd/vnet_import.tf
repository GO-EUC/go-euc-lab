data "azurerm_virtual_network" "AzurevNet" {
  name                = var.azure_vnet_name
  resource_group_name = var.azure_vnet_resource_group_name
}

data "azurerm_subnet" "AzureSubnet" {
  name                 = var.azure_subnet_name
  resource_group_name  = var.azure_vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.AzurevNet.name
}