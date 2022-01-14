resource "azurerm_resource_group" "AVD" {
  name     = "rg-${var.deployment_name}-${var.workspace}-avd"
  location = var.location
}
