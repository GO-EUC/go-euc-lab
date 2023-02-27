locals {
  template_windows_2022 = jsondecode(file("${var.root_path}/manifests/windows-server-2022-standard.json"))
  
  vsphere_server = cidrhost(jsondecode(data.vault_kv_secret.network.data_json).cidr ,jsondecode(data.vault_kv_secret.vcsa.data_json).ip)
  vsphere_user = jsondecode(data.vault_kv_secret.vcsa.data_json).user
  vsphere_password = jsondecode(data.vault_kv_secret.vcsa.data_json).password
  
  # Note, the first host will be used to the primary deployments
  vsphere_nic = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[0]].data_json).network
  vsphere_datastore = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[0]].data_json).datastore

  domain = jsondecode(data.vault_kv_secret.domain.data_json).name
  build_password = jsondecode(data.vault_kv_secret.build.data_json).password

  nic_cidr = jsondecode(data.vault_kv_secret.network.data_json).cidr
  nic_gateway = jsondecode(data.vault_kv_secret.network.data_json).gateway
  nic_main_dns = jsondecode(data.vault_kv_secret.network.data_json).dns
  nic_custom_dns = jsondecode(data.vault_kv_secret.vcsa.data_json).dns
}

module "domain_controller" {
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = "dc"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  network_address                = cidrhost(local.nic_cidr, var.network_list[0])
  network_gateway                = cidrhost(local.nic_cidr, local.nic_gateway)
  network_dns_list               = [cidrhost(local.nic_cidr, local.nic_main_dns), cidrhost(local.nic_cidr, local.nic_custom_dns)]
  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "management_server" {
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name   = "mngt"
  vm_cpu    = 4
  vm_memory = 4096
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
    }, {
    unit_number = 1
    label       = "data"
    size        = 512
  }]

  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  network_address                = cidrhost(local.nic_cidr, var.network_list[1])
  network_gateway                = cidrhost(local.nic_cidr, local.nic_gateway)
  network_dns_list               = [ cidrhost(local.nic_cidr, var.network_list[0]), cidrhost(local.nic_cidr, local.nic_main_dns) ]
  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "sql_server" {
  source    = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name   = "sql"
  vm_cpu    = 4
  vm_memory = 4096
  vm_disks = [{
    unit_number = 0
    label       = "os"
    size        = 100
    }, {
    unit_number = 1
    label       = "mssqldata"
    size        = 64
  }]

  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  network_address                = cidrhost(local.nic_cidr, var.network_list[2])
  network_gateway                = cidrhost(local.nic_cidr, local.nic_gateway)
  network_dns_list               = [ cidrhost(local.nic_cidr, var.network_list[0]), cidrhost(local.nic_cidr, local.nic_main_dns) ]
  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter = var.vsphere_datacenter
  vsphere_datastore  = local.vsphere_datastore
  vsphere_cluster    = var.vsphere_cluster

  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "citrix_cloud_connectors" {
  count  = var.citrix_cloud ? 1 : 0
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_count              = 2
  vm_name               = "ctx-cc"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "citrix_storefront" {
  count  = var.citrix_vad ? 1 : 0
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = "ctx-sf"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "citrix_delivery_controller" {
  count  = var.citrix_vad ? 1 : 0
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = "ctx-dc"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "citrix_license_server" {
  count  = var.citrix_vad ? 1 : 0
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = "ctx-lic"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}

module "vmware_horizon" {
  count  = var.vmware_horizon ? 1 : 0
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = "vmw-hcs"
  vm_cpu                = 4
  vm_memory             = 4096
  local_admin_password  = local.build_password
  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = random_password.password.result

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_2022.builds[0].artifact_id
}