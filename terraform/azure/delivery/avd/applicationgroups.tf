resource "azurerm_virtual_desktop_application_group" "applicationgroup" {
  name                = "vdag-${var.deployment_name}-${var.workspace}"
  location            = azurerm_resource_group.GO-AVD.location
  resource_group_name = azurerm_resource_group.GO-AVD.name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.hostpool.id
  friendly_name = "${var.deployment_name} - Appgroup"
  description   = "${var.deployment_name}: An application group"
  tags = {
    "description" = "${var.deployment_name}: An application group"
  }
}