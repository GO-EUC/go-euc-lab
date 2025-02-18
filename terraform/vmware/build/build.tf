module "build" {
  source = "../modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = var.build_name
  vm_cpu                = 4
  vm_memory             = 16384
  vm_guest_id           = "windows9_64Guest"
  local_admin_password  = local.build_password

  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = local.build_password

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template.builds[0].artifact_id
}