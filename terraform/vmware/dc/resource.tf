module "ActiveDirectory" {
  source                = "../modules/vmware.vsphere.vm.windows"
  vm_name               = "${local.environment_abbreviations[terraform.workspace]}-dc"
  vm_cpu                = 4
  vm_memory             = 8192
  local_admin_password  = var.local_admin_password
  domain                = local.ad_domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  network_address                = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 1)   #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  network_gateway                = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 254) #matches to the 254th IP address of the address space I.E. "172.16.0.254"
  virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

  vsphere_datacenter      = local.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = local.vsphere_cluster
  vsphere_source_template = local.vsphere_source_template_windows
}