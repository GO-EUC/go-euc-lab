resource "azurerm_mssql_server" "sql" {
  name                         = "sql-infra-${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name          = azurerm_resource_group.SQL.name
  location                     = azurerm_resource_group.SQL.location
  version                      = "12.0"
  administrator_login          = azurerm_key_vault_secret.sql_admin.name
  administrator_login_password = azurerm_key_vault_secret.sql_admin.value
}

resource "azurerm_mssql_database" "loadgen" {
  name           = "db-infra-loadgen-${local.environment_abbreviations[terraform.workspace]}"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "Basic"
}