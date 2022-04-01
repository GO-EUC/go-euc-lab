resource "azurerm_managed_disk" "manageddisk" {
  count                 = var.managed_disk_enabled != null ? 1 : 0
  name                  = "${var.vm_name}-${var.vm_count}-manageddisk"
  location              = var.azure_location
  resource_group_name   = var.azure_resource_group_name
  storage_account_type  = "Standard_LRS"
  create_option         = "Empty"
  disk_size_gb          = "20"
}  