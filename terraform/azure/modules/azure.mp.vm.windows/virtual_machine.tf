#try without KeyVault, since LAB HTTP is good enough for WinRM

resource "azurerm_virtual_machine" "AzureVM" {
  count                 = var.vm_count
  name                  = "${var.vm_name}-${count.index + 1}"
  location              = var.azure_location
  resource_group_name   = var.azure_resource_group_name
  network_interface_ids = [azurerm_network_interface.AzureNic[count.index].id]
  vm_size               = var.azure_vm_sku
  availability_set_id   = azurerm_availability_set.availabilityset.id
  #zones                             = [ element(["1", "2", "3"], (count.index)) ] # If Availability Zone is needed, please uncomment Availabilty Zone and Comment Availablity Set
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  license_type                     = "Windows_Server"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.azure_image_sku
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm_name}-${count.index + 1}-osDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.azure_mananaged_disk_type
  }

  storage_data_disk {
    name            = azurerm_managed_disk.manageddisk[0].name
    managed_disk_id = azurerm_managed_disk.manageddisk[0].id
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = azurerm_managed_disk.manageddisk[0].disk_size_gb
  }

  os_profile {
    computer_name  = "${var.vm_name}-${count.index + 1}"
    admin_username = var.local_admin
    admin_password = var.local_admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
    timezone                  = var.azure_vm_timezone

    winrm {
      protocol = "HTTP"
    }
  }
}