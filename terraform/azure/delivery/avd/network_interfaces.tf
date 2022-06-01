resource "azurerm_network_interface" "AzureNic" {
  count               = var.sessionhost_amount
  name                = "${var.workspace}-AVDSH-${count.index + 1}-nic"
  location            = azurerm_resource_group.GO-AVDSH.location
  resource_group_name = azurerm_resource_group.GO-AVDSH.name

  ip_configuration {
    name                          = "${var.workspace}-AVDSH-${count.index + 1}-ip"
    subnet_id                     = data.azurerm_subnet.AzureSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}