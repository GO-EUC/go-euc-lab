
module "ManagementServer" {
  source    = "./modules/vmware.vsphere.vm.windows"
  vm_name   = "${local.environment_abbreviations[terraform.workspace]}-mgnt"
  vm_cpu    = 4
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

# module "FileServer" {
#   source    = "./modules/vmware.vsphere.vm.windows"
#   vm_name   = "${local.environment_abbreviations[terraform.workspace]}-fs"
#   vm_cpu    = 4
#   vm_memory = 4096
#   vm_disks = [{
#     unit_number = 0
#     label       = "os"
#     size        = 100
#     }, {
#     unit_number = 1
#     label       = "data"
#     size        = 512
#   }]

#   virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

#   local_admin_password  = var.local_admin_password
#   domain                = local.ad_domain_fqdn
#   domain_admin          = var.domain_admin
#   domain_admin_password = var.domain_admin_password

#   vsphere_datacenter      = local.vsphere_datacenter
#   vsphere_datastore       = local.vsphere_datastore
#   vsphere_cluster         = local.vsphere_cluster
#   vsphere_source_template = local.vsphere_source_template_windows
# }

# module "RemoteGateway" {
#   source    = "./modules/vmware.vsphere.vm.windows"
#   vm_name   = "${local.environment_abbreviations[terraform.workspace]}-rdgw"
#   vm_cpu    = 4
#   vm_memory = 4096

#   virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

#   local_admin_password  = var.local_admin_password
#   domain                = local.ad_domain_fqdn
#   domain_admin          = var.domain_admin
#   domain_admin_password = var.domain_admin_password

#   vsphere_datacenter      = local.vsphere_datacenter
#   vsphere_datastore       = local.vsphere_datastore
#   vsphere_cluster         = local.vsphere_cluster
#   vsphere_source_template = local.vsphere_source_template_windows
# }

# module "SQLServer" {

#   source    = "./modules/vmware.vsphere.vm.windows"
#   vm_name   = "${local.environment_abbreviations[terraform.workspace]}-sql"
#   vm_cpu    = 4
#   vm_memory = 8192
#   vm_disks = [{
#     unit_number = 0
#     label       = "os"
#     size        = 100
#     }, {
#     unit_number = 1
#     label       = "mssqldata"
#     size        = 64
#   }]
#   virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

#   local_admin_password  = var.local_admin_password
#   domain                = local.ad_domain_fqdn
#   domain_admin          = var.domain_admin
#   domain_admin_password = var.domain_admin_password

#   vsphere_datacenter      = local.vsphere_datacenter
#   vsphere_datastore       = local.vsphere_datastore
#   vsphere_cluster         = local.vsphere_cluster
#   vsphere_source_template = local.vsphere_source_template_windows
# }

# module "CVAD" {
#   count  = local.delivery_solutions[var.delivery] == "cvad" ? 1 : 0
#   source = "./delivery/cvad"

# }

# module "Bots" {
#   source    = "./modules/vmware.vsphere.vm.windows"
#   vm_count  = 10
#   vm_name   = "${local.environment_abbreviations[terraform.workspace]}-bot"
#   vm_cpu    = 4
#   vm_memory = 8192
#   vm_disks = [{
#     unit_number = 0
#     label       = "disk0"
#     size        = 128
#   }]
#   local_admin_password  = var.local_admin_password
#   domain                = local.ad_domain_fqdn
#   domain_admin          = var.domain_admin
#   domain_admin_password = var.domain_admin_password

#   virtual_network_portgroup_name = local.virtual_network_portgroup_name[terraform.workspace]

#   vsphere_datacenter      = local.vsphere_datacenter
#   vsphere_datastore       = local.vsphere_datastore
#   vsphere_cluster         = local.vsphere_cluster
#   vsphere_source_template = local.vsphere_source_template_windows
# }