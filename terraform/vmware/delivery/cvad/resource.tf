module "citrix_license_server" {
  source    = "../../modules/vmware.vsphere.vm.windows"
  vm_name   = "${local.environment_abbreviations[terraform.workspace]}-ctxlic"
  vm_cpu    = 2
  vm_memory = 4096
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]
  local_admin_password  = var.local_admin_password
  domain                = local.ad_domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

  vsphere_datacenter      = local.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = local.vsphere_cluster
  vsphere_source_template = local.vsphere_source_template_windows
}


module "citrix_delivery_controller" {
  source    = "../../modules/vmware.vsphere.vm.windows"
  vm_name   = "${local.environment_abbreviations[terraform.workspace]}-ctxddc"
  vm_cpu    = 4
  vm_memory = 8192
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]
  local_admin_password  = var.local_admin_password
  domain                = local.ad_domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

  vsphere_datacenter      = local.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = local.vsphere_cluster
  vsphere_source_template = local.vsphere_source_template_windows
}

module "citrix_storefront" {
  source    = "./modules/vmware.vsphere.vm.windows"
  vm_name   = "${local.environment_abbreviations[terraform.workspace]}-ctxsf"
  vm_cpu    = 2
  vm_memory = 6144
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]
  local_admin_password  = var.local_admin_password
  domain                = local.ad_domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

  vsphere_datacenter      = local.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = local.vsphere_cluster
  vsphere_source_template = local.vsphere_source_template_windows
}