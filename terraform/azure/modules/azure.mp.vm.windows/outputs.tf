output "vm_info" {
    value = formatlist("%s ansible_host=%s", azurerm_virtual_machine.AzureVM[*].name, azurerm_network_interface.AzureNic[*].private_ip_address)
}
