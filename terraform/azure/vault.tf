data "azurerm_client_config" "current" {}

resource "random_integer" "vault" {
  min = 10000
  max = 99999
}

resource "azurerm_key_vault" "vault" {
  name                = "kv-infra-${local.environment_abbreviations[terraform.workspace]}-${random_integer.vault.result}"
  location            = azurerm_resource_group.Vault.location
  resource_group_name = azurerm_resource_group.Vault.name

  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  # network_acls {
  #     default_action = "Deny"
  #     bypass = "AzureServices"
  #     ip_rules = [ var.myip ]
  #     virtual_network_subnet_ids = [azurerm_subnet.infra_subnet.id, azurerm_subnet.container_subnet.id]
  # }

  # depends_on = [azurerm_resource_group.infra_resourcegroup]
}

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!@#$()"
  min_special      = 3
  min_numeric      = 3
  min_lower        = 3
  min_upper        = 3
  special          = true

  # depends_on = [azurerm_key_vault.vault]
}

resource "azurerm_key_vault_secret" "admin" {
  name         = "${local.environment_abbreviations[terraform.workspace]}-admin"
  value        = random_password.admin_password.result
  key_vault_id = azurerm_key_vault.vault.id

  # depends_on = [azurerm_key_vault.vault, random_password.admin_password]
}