resource "azurerm_windows_virtual_machine" "sessionhostvms" {
  count               = var.sessionhost_amount
  name                = "${var.workspace}-AVDSH-${count.index + 1}"
  resource_group_name = azurerm_resource_group.GO-AVDSH.name
  location            = azurerm_resource_group.GO-AVDSH.location
  size                = var.sessionhost_sku
  admin_username      = var.local_admin
  admin_password      = var.local_admin_password
  network_interface_ids = [azurerm_network_interface.AzureNic[count.index].id]
  provision_vm_agent = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
  }
}