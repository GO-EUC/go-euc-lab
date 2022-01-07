module "ActiveDirectory" {
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-dc"

    azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 10

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "active_directory.yml"
    #TO-DO: Disable DHCP Server for Azure
    #ansible_arguments               = "-e reverse_dns_zone=${local.virtual_network_cidr_address[terraform.workspace]} -e recovery_password=${var.domain_admin_password} -e public_dns1=8.8.8.8 -e public_dns2=8.8.4.4 -e public_ntp=0.nl.pool.ntp.org,1.nl.pool.ntp.org -e dhcp_start_range=${cidrhost(local.virtual_network_cidr_address[terraform.workspace], 11)} -e dhcp_end_range=${cidrhost(local.virtual_network_cidr_address[terraform.workspace], 253)} -e dhcp_subnetmask=${cidrnetmask(local.virtual_network_cidr_address[terraform.workspace])} -e dhcp_router=${cidrhost(local.virtual_network_cidr_address[terraform.workspace], 254)}"
}

module "ManagementServer" {
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}--mgnt"

    azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 15

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "management_server.yml"
    #ansible_arguments               = "-e environment_abbreviations=${local.environment_abbreviations[terraform.workspace]} -e netbios_domain=GO"

    depends_on                      = [module.ActiveDirectory]
}

module "FileServer" {
    #TO-DO: Add extra datadisk or move to Azure Files. Use MGMT server for AD Join Azure Files
    #TO-DO: Download CVAD ISO not needed
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-fs"

    azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 20

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "file_server.yml"
    #ansible_arguments               = "-e installsrc_storageaccountsmb=${var.installsrc_storageaccountsmb} -e installsrc_storageaccountusername=${var.installsrc_storageaccountusername} -e installsrc_storageaccountpwd=${var.installsrc_storageaccountpwd}"
    
    depends_on                      = [module.ActiveDirectory]
}


#Remote Gateway not needed, configured Bastion

#TO-DO Azure SQL

module "CitrixCloudConnector" {
    #TO-DO: Add playbook Fileserver with API keys
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-cc"
    vm_count                        = 2

    azure_resource_group_name       = azurerm_resource_group.InfraBackend.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 25

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "file_server.yml"
    #ansible_arguments               = "-e installsrc_storageaccountsmb=${var.installsrc_storageaccountsmb} -e installsrc_storageaccountusername=${var.installsrc_storageaccountusername} -e installsrc_storageaccountpwd=${var.installsrc_storageaccountpwd}"
    
    depends_on                      = [module.ActiveDirectory]
}

module "LoadGen-Server" {
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-lgen"
    azure_vm_sku                    = "Standard_D4s_v4"

    azure_resource_group_name       = azurerm_resource_group.Loadgen.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 30

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "loadgen_server.yml"
    #ansible_arguments               = "-e environment_abbreviations=${local.environment_abbreviations[terraform.workspace]} -e netbios_domain=GO"
    
    depends_on                      = [module.MicrosoftSQLServer,module.FileServer]
}

module "LoadGen-Bot" {
    source                          = "./modules/azure.mp.vm.windows"

    vm_name                         = "${local.environment_abbreviations[terraform.workspace]}-bot"
    vm_count                        = 2
    azure_vm_sku                    = "Standard_D4s_v4"

    azure_resource_group_name       = azurerm_resource_group.Loadgen.name

    azure_vnet_name                 = data.azurerm_virtual_network.AzurevNet.name
    azure_vnet_resource_group_name  = var.import_vnet_resourcegroup
    azure_subnet_name               = data.azurerm_subnet.backend.name
    azure_cidr_host_start           = 35

    local_admin_password            = var.local_admin_password
    domain                          = local.ad_domain_fqdn
    domain_admin                    = var.domain_admin
    domain_admin_password           = var.domain_admin_password

    #ansible_playbook                = "loadgen_bot.yml"
    #ansible_arguments               = "-e environment_abbreviations=${local.environment_abbreviations[terraform.workspace]} -e netbios_domain=GO"
    
    depends_on                      = [module.MicrosoftSQLServer,module.FileServer]
}