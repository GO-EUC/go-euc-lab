resource "azurerm_virtual_desktop_host_pool" "this" {
  resource_group_name               = var.avd_hp_rg
  location                          = var.azure_region
  name                              = var.avd_hp_name
  friendly_name                     = var.avd_hp_friendlyname
  validate_environment              = var.avd_hp_validate
  custom_rdp_properties             = var.avd_hp_custom_rdp_properties 
  description                       = var.avd_hp_desc
  type                              = var.avd_hp_type
  maximum_sessions_allowed          = var.avd_hp_type == "Pooled" ? var.avd_hp_maxsessions : null
  load_balancer_type                = var.avd_hp_type == "Pooled" ? var.avd_hp_lbtype : null
  personal_desktop_assignment_type  = var.avd_hp_type == "Personal" ? var.avd_hp_personaldesktopassignment_type : null
}

resource "time_offset" "this" {
  offset_days = 30
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = time_offset.this.rfc3339
}

