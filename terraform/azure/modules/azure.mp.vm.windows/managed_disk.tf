resource "azurerm_managed_disk" "manageddisk" {
  count                 = var.managed_disk_count
  vmcount              = var.vm_count
  name                  = "${var.vm_name}${vmcount.index + 1}-manageddisk${count.index + 1}"
  location = var.azure_location
  resource_group_name = var.azure_resource_group_name
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = "20"
}  