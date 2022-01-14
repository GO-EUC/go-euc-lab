module "ActiveDirectory" {
  source = "./modules/azure.mp.vm.windows.static"

  vm_name = "${local.environment_abbreviations[terraform.workspace]}-dc"

  azure_resource_group_name = azurerm_resource_group.InfraBackend.name

  azure_vnet_name                = azurerm_virtual_network.AzurevNet.name
  azure_vnet_resource_group_name = azurerm_virtual_network.AzurevNet.resource_group_name
  azure_subnet_name              = azurerm_subnet.backend.name
  azure_cidr_host_start          = 10


  local_admin_password = azurerm_key_vault_secret.admin.value
  local_admin          = azurerm_key_vault_secret.admin.name

  depends_on = [azurerm_virtual_network.AzurevNet]
}

module "ManagementServer" {
  source                          = "./modules/azure.mp.vm.windows"
  vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-mgnt"

  azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

  azure_vnet_name                = azurerm_virtual_network.AzurevNet.name
  azure_vnet_resource_group_name = azurerm_virtual_network.AzurevNet.resource_group_name
  azure_subnet_name              = azurerm_subnet.backend.name

  local_admin_password = azurerm_key_vault_secret.admin.value
  local_admin          = azurerm_key_vault_secret.admin.name

  depends_on = [azurerm_virtual_network.AzurevNet]
}

module "CVADs" {
  count    = local.delivery_solutions[var.delivery] == "cvads" ? 1 : 0
  source = "./delivery/cvads"

  location              = local.azure_location

  deployment_name       = local.deploymentname
  workspace             = local.environment_abbreviations[terraform.workspace]

  azure_vnet_name                = azurerm_virtual_network.AzurevNet.name
  azure_vnet_resource_group_name = azurerm_virtual_network.AzurevNet.resource_group_name
  azure_subnet_name              = azurerm_subnet.backend.name

  local_admin_password = azurerm_key_vault_secret.admin.value
  local_admin          = azurerm_key_vault_secret.admin.name

  depends_on = [azurerm_virtual_network.AzurevNet]
}

module "AVD" {
  count    = local.delivery_solutions[var.delivery] == "avd" ? 1 : 0
  source = "./delivery/avd"

  location              = local.azure_location

  deployment_name       = local.deploymentname
  workspace             = local.environment_abbreviations[terraform.workspace]

  depends_on = [azurerm_virtual_network.AzurevNet]
}


# #Remote Gateway not needed, configured Bastion

# #TO-DO Azure SQL

# module "CitrixCloudConnector" {
#     #TO-DO: Add playbook Fileserver with API keys
#     source                          = "./modules/azure.mp.vm.windows"

#     vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-cc"
#     vm_count                        = 2

#     azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

#     azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
#     azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
#     azure_subnet_name               = data.azurerm_subnet.backend.name
#     azure_cidr_host_start           = 25

#     local_admin_password            = var.local_admin_password
#     domain                          = local.ad_domain_fqdn
#     domain_admin                    = var.domain_admin
#     domain_admin_password           = var.domain_admin_password

#     depends_on                      = [module.ActiveDirectory]
# }

# module "LoadGen-Server" {
#     source                          = "./modules/azure.mp.vm.windows"

#     vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-lgen"
#     azure_vm_sku                    = "Standard_D4s_v4"

#     azure_resource_group_name       = azurerm_resource_group.Loadgen.name

#     azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
#     azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
#     azure_subnet_name               = data.azurerm_subnet.backend.name
#     azure_cidr_host_start           = 30

#     local_admin_password            = var.local_admin_password
#     domain                          = local.ad_domain_fqdn
#     domain_admin                    = var.domain_admin
#     domain_admin_password           = var.domain_admin_password

#    depends_on                      = [module.MicrosoftSQLServer,module.FileServer]
# }

# module "LoadGen-Bot" {
#     source                          = "./modules/azure.mp.vm.windows"

#     vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-bot"
#     vm_count                        = 2
#     azure_vm_sku                    = "Standard_D4s_v4"

#     azure_resource_group_name       = azurerm_resource_group.Loadgen.name

#     azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
#     azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
#     azure_subnet_name               = data.azurerm_subnet.backend.name
#     azure_cidr_host_start           = 35

#     local_admin_password            = var.local_admin_password
#     domain                          = local.ad_domain_fqdn
#     domain_admin                    = var.domain_admin
#     domain_admin_password           = var.domain_admin_password

#    depends_on                      = [module.MicrosoftSQLServer,module.FileServer]
# }