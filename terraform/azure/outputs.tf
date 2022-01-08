output "vault" {
  description = "The name of the Azure Key Vault"
  value       = azurerm_key_vault.vault.name
}

output "vault_resource_group" {
  description = "The resource group name of the Azure Key Vault"
  value       = azurerm_key_vault.vault.resource_group_name
}

output "admin" {
  description = "Local administrator account name"
  value       = azurerm_key_vault_secret.admin.name
}

output "reverse_dns_zone" {
  description = "Infra subnet for reverse dns zone in the domain controller"
  value       = local.infra_subnet_cidr[terraform.workspace]
}

output "dc" {
  value = module.ActiveDirectory.vm_info
}

output "cc" {
  value = module.CitrixCloudConnectors.vm_info
}