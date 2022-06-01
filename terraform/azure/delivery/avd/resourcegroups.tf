resource "azurerm_resource_group" "GO-AVD" {
  name     = "rg-${var.deployment_name}-${var.workspace}-AVD"
  location = var.location
  tags = {
    "description" = "Resource group for AVD Components"
  }
}

resource "azurerm_resource_group" "GO-AVDSH" {
  name     = "rg-${var.deployment_name}-${var.workspace}-AVDSH"
  location = var.location
  tags = {
    "description" = "Resource group for AVD Session Hosts"
  }
}