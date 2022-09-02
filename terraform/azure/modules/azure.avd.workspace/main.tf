resource "azurerm_virtual_desktop_workspace" "this" {
  name                = var.avd_workspace_name
  resource_group_name = var.avd_rg_name
  location            = var.azure_region
  friendly_name       = "${var.prefix} Workspace"
  description         = "${var.prefix} Workspace"

    lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["DateCreated"] 
    ]
  }
}


