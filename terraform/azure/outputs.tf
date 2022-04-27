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

output "sql_admin" {
  description = "SQL administrator account name"
  value       = azurerm_key_vault_secret.sql_admin.name
}

output "sql_server" {
  description = "Infra SQL server name"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database" {
  description = "Infra SQL server database for LoadGen"
  value       = azurerm_mssql_database.loadgen.name
}

output "dc" {
  value = module.ActiveDirectory.vm_info
}

output "mgnt" {
  value = module.ManagementServer.vm_info
}

output "cc" {
 value = module.CVADs[*].vm_info
}
