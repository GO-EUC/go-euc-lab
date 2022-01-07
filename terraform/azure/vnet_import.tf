#Used to import existing vNet config where the DevOps agent has private access
data "azurerm_virtual_network" "AzurevNet" {
    name                = local.import_vnet_name
    resource_group_name = var.import_vnet_resourcegroup
}