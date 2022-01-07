resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host-${local.environment_abbreviations[terraform.workspace]}"
  location            = local.azure_location
  resource_group_name = azurerm_resource_group.Bastion.name
  ip_configuration {
    name                 = "bastion-ip-configuration-${local.environment_abbreviations[terraform.workspace]}"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.pip-bastion.id
  }
}