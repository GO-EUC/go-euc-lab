resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "workspace-${var.deployment_name}-${var.workspace}"
  
  resource_group_name = azurerm_resource_group.AVD.name
  location            = azurerm_resource_group.AVD.location
  friendly_name       = "${var.workspace} AVD Workspace"
  description         = "Workspace"

}

resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  resource_group_name      = azurerm_resource_group.AVD.name
  location                 = azurerm_resource_group.AVD.location
  
  name                     = "hostpool-${var.deployment_name}-${var.workspace}"
  friendly_name            = "hostpool-${var.deployment_name}-${var.workspace}"
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  description              = "${var.workspace} AVD Hostpool"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "DepthFirst" #[BreadthFirst DepthFirst]
}

resource "azurerm_virtual_desktop_application_group" "dag" {
 
  resource_group_name = azurerm_resource_group.AVD.name
  
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  location            = azurerm_resource_group.AVD.location
  
  type                = "Desktop"
  name                = "dag-${var.deployment_name}-${var.workspace}"
  
  friendly_name       = "${var.workspace} Desktop AppGroup"
  description         = "${var.workspace} AVD application group"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}