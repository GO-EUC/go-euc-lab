output "hostpool_id" {
  value       = azurerm_virtual_desktop_host_pool.this.id
  description = "Hostpool ID" 
}

output "azure_virtual_desktop_host_pool" {
  description = "Name of the Azure Virtual Desktop host pool"
  value       = azurerm_virtual_desktop_host_pool.this.name
}

output "hostpool_token" {
  value       = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
  description = "hostpool token required for workloads to join the pool" 
  sensitive = true
}



