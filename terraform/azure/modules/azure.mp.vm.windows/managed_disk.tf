
resource "azurerm_managed_disk" "manageddisk" {
  count                  = length(var.managed_disks)
  name                  = "${var.vm_name}-${var.vm_count}-${var.managed_disks[count.index].name}-manageddisk"
  location              = var.azure_location
  resource_group_name   = var.azure_resource_group_name
  storage_account_type  = var.managed_disks[count.index].storage_account_type
  create_option         = var.managed_disks[count.index].create_option
  disk_size_gb          = var.managed_disks[count.index].disk_size_gb
}