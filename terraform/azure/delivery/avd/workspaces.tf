resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "vdws-${var.deployment_name}-${var.workspace}"
  location            = azurerm_resource_group.GO-AVD.location
  resource_group_name = azurerm_resource_group.GO-AVD.name

  friendly_name = "GO-EUC Workspace"
  description   = "This is our lab AVD workspace in ${var.location}"
  tags = {
    "description" = "${var.deployment_name}: An AVD Workspace"
  }
}