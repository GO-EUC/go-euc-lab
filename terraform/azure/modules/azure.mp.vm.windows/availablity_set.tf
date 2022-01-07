resource "azurerm_availability_set" "availabilityset" {
    name                          = "as-${var.vm_name}"
    location                      = var.azure_location
    resource_group_name           = var.azure_resource_group_name
    platform_fault_domain_count   = var.azure_fault_domain_count
    platform_update_domain_count  = var.azure_update_domain_count
}