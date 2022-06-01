data "azuread_user" "aad_user" {
  for_each            = toset(var.avd_users)
  user_principal_name = format("%s", each.key)
}

data "azurerm_role_definition" "role" {
  name = "Desktop Virtualization User"
}

resource "azuread_group" "aad_group" {
  display_name     = "aadgroup-${azurerm_virtual_desktop_application_group.applicationgroup.name}"
  security_enabled = true
}

resource "azuread_group_member" "aad_group_member" {
  for_each         = data.azuread_user.aad_user
  group_object_id  = azuread_group.aad_group.id
  member_object_id = each.value["id"]
}

resource "azurerm_role_assignment" "role" {
  scope              = azurerm_virtual_desktop_application_group.applicationgroup.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = azuread_group.aad_group.id
}
