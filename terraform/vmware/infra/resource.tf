module "vcsa" {
  count  = var.vsphere_deploy == true ? 1 : 0
  source = "./modules/vmware.vcsa"

  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_datastore  = var.vsphere_datastore
  vsphere_nic        = var.vsphere_nic
  vsphere_nic_cidr   = var.vsphere_nic_cidr
  vsphere_hosts      = var.vsphere_hosts

  esx_username = var.esx_username
  esx_password = var.esx_password
}

module "domain_controller" {
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  vm_name               = "dc"
  vm_cpu                = 4
  vm_memory             = 2048
  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  network_address                = cidrhost(var.vsphere_nic_cidr, 2)   #matches to the 2st IP address of the address space I.E. "172.16.0.2"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)   #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows

  depends_on = [
    module.vcsa
  ]
}

module "management_server" {
  source = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

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

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  network_address                = cidrhost(var.vsphere_nic_cidr, 3)                                      #matches to the 2st IP address of the address space I.E. "172.16.0.3"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)                                      #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 2), cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows

  depends_on = [
    module.vcsa
  ]
}

module "sql_server" {
  source    = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

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

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  network_address                = cidrhost(var.vsphere_nic_cidr, 4)                                      #matches to the 2st IP address of the address space I.E. "172.16.0.4"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)                                      #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 2), cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  vsphere_datacenter = var.vsphere_datacenter
  vsphere_datastore  = var.vsphere_datastore
  vsphere_cluster    = var.vsphere_cluster

  vsphere_source_template = var.vsphere_source_template_windows

  depends_on = [
    module.vcsa
  ]
}

module "citrix_delivery_controller" {
  count  = local.delivery_solutions[var.delivery] == "cvad" ? 1 : 0

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  source    = "./modules/vmware.vsphere.vm.windows"
  vm_name   = "ctxddc"
  vm_cpu    = 2
  vm_memory = 2048
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]

  network_address                = cidrhost(var.vsphere_nic_cidr, 20)                                      #matches to the 2st IP address of the address space I.E. "172.16.0.4"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)                                      #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 2), cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows
}

module "citrix_storefront" {
  count  = local.delivery_solutions[var.delivery] == "cvad" ? 1 : 0

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  source    = "./modules/vmware.vsphere.vm.windows"
  vm_name   = "ctxsf"
  vm_cpu    = 2
  vm_memory = 2048
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]

  network_address                = cidrhost(var.vsphere_nic_cidr, 21)                                      #matches to the 2st IP address of the address space I.E. "172.16.0.4"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)                                      #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 2), cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows
}

module "citrix_license_server" {
  count  = local.delivery_solutions[var.delivery] == "cvad" ? 1 : 0

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  source    = "./modules/vmware.vsphere.vm.windows"
  vm_name   = "ctxlic"
  vm_cpu    = 2
  vm_memory = 2048
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]

  network_address                = cidrhost(var.vsphere_nic_cidr, 22)                                      #matches to the 2st IP address of the address space I.E. "172.16.0.4"
  network_gateway                = cidrhost(var.vsphere_nic_cidr, 1)                                      #matches to the 1th IP address of the address space I.E. "172.16.0.1"
  network_dns_list               = [cidrhost(var.vsphere_nic_cidr, 2), cidrhost(var.vsphere_nic_cidr, 1)] #matches to the 1st IP address of the address space I.E. "172.16.0.1"
  virtual_network_portgroup_name = var.vsphere_nic

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = var.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows
}

module "vmware_connection_server" {
  source    = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  vm_count  = 1
  vm_name   = "vcs"
  vm_cpu    = 4
  vm_memory = 2048
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  virtual_network_portgroup_name = var.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = "datastore2"
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows
}

module "Bots" {
  source    = "./modules/vmware.vsphere.vm.windows"

  vsphere_server   = var.vsphere_server
  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password

  vm_count  = 2
  vm_name   = "bot"
  vm_cpu    = 4
  vm_memory = 2048
  vm_disks = [{
    unit_number = 0
    label       = "disk0"
    size        = 128
  }]

  local_admin_password  = var.local_admin_password
  domain                = var.domain_fqdn
  domain_admin          = var.domain_admin
  domain_admin_password = var.domain_admin_password

  virtual_network_portgroup_name = var.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = "datastore2"
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = var.vsphere_source_template_windows
}