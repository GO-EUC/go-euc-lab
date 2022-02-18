resource "azurerm_managed_disk" "manageddisk" {
  vmcount               = var.vm_count
  count                 = var.managed_disk_count
  name                  = "${var.vm_name}${vmcount.index + 1}-manageddisk${count.index + 1}"
  #name = "${var.vm_name}-manageddisk"
  location = var.azure_location
  resource_group_name = var.azure_resource_group_name
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = "20"
}  