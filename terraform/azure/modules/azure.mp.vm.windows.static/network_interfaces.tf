resource "azurerm_network_interface" "AzureNic" {
  count               = var.vm_count
  name                = "${var.vm_name}${count.index + 1}-nic"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  ip_configuration {
    name                          = "${var.vm_name}${count.index + 1}-ip"
    subnet_id                     = data.azurerm_subnet.AzureSubnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = cidrhost(data.azurerm_subnet.AzureSubnet.address_prefixes[0] , var.azure_cidr_host_start)
  }
}