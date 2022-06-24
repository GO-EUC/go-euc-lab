resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  location            = azurerm_resource_group.GO-AVD.location
  resource_group_name = azurerm_resource_group.GO-AVD.name

  name                     = "vdpool-${var.deployment_name}-${var.workspace}"
  friendly_name            = "This is our lab AVD host pool in ${var.location}"
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  description              = "${var.deployment_name}: A pooled host pool - BreadthFirst"
  validate_environment     = true
  start_vm_on_connect      = true
  maximum_sessions_allowed = 50
  preferred_app_group_type = "Desktop"

  tags = {
    "description" = "${var.deployment_name}: A pooled host pool - BreadthFirst"
  }
}