module "cloudconnectors" {
  source   = "../../modules/azure.mp.vm.windows"
  vm_count = 2
  vm_name  = "${var.workspace}-cc"

  azure_resource_group_name = azurerm_resource_group.CVADs.name
  azure_location            = var.location

  azure_vnet_name                = var.azure_vnet_name
  azure_vnet_resource_group_name = var.azure_vnet_resource_group_name
  azure_subnet_name              = var.azure_subnet_name


  local_admin_password = var.local_admin_password
  local_admin          = var.local_admin 
}