resource "azurerm_resource_group" "CVADs" {
  name     = "rg-${var.deployment_name}-${var.workspace}-cvads"
  location = var.location
}
