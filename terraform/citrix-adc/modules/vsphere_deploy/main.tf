#####
# Define Locals
#####
locals {
  networkstring = "ip=${var.vm.ip}&netmask=${var.vm.netmask}&gateway=${var.vm.gateway}"
}

#####
# Configure Datacenter
#####
data "vsphere_datacenter" "dc" {
  name = var.vsphere.datacenter
}

#####
# Configure Datastore
#####
data "vsphere_datastore" "datastore" {
  name          = var.vsphere.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

#####
# Configure Host
#####
data "vsphere_host" "host" {
  name          = var.vsphere.host
  datacenter_id = data.vsphere_datacenter.dc.id
}

#####
# Configure Ressource Pool
#####
data "vsphere_resource_pool" "pool" {
  name          = var.vsphere.resourcepool
  datacenter_id = data.vsphere_datacenter.dc.id
}

#####
# Configure VM Network
#####
data "vsphere_network" "network" {
  name          = var.vm.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

#####
# Configure OVF
#####
data "vsphere_ovf_vm_template" "ovfLocal" {
  name              = "TemporaryName"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_resource_pool.pool.id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  local_ovf_path    = var.vm.ovf

  ovf_network_map = {
    "VM Network" : data.vsphere_network.network.id
  }
}

#####
# Create ADC VM
#####
resource "vsphere_virtual_machine" "build_citrix-adc" {
  name                 = var.vm.name
  datacenter_id        = data.vsphere_datacenter.dc.id
  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  num_cpus             = data.vsphere_ovf_vm_template.ovfLocal.num_cpus
  num_cores_per_socket = data.vsphere_ovf_vm_template.ovfLocal.num_cores_per_socket
  memory               = data.vsphere_ovf_vm_template.ovfLocal.memory
  guest_id             = data.vsphere_ovf_vm_template.ovfLocal.guest_id
  scsi_type            = data.vsphere_ovf_vm_template.ovfLocal.scsi_type
  nested_hv_enabled    = data.vsphere_ovf_vm_template.ovfLocal.nested_hv_enabled
  
  network_interface {
    network_id     = values(data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map)[0]
    use_static_mac = true
    mac_address    = var.vm.mac
  }
  
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 5

  ovf_deploy {
    allow_unverified_ssl_cert = false
    local_ovf_path            = data.vsphere_ovf_vm_template.ovfLocal.local_ovf_path
    disk_provisioning         = data.vsphere_ovf_vm_template.ovfLocal.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
  }

  extra_config = {
    "machine.id" = local.networkstring
  }
}

#####
# Wait a few seconds
#####
resource "time_sleep" "build_wait_a_few_seconds" {

  create_duration = "180s"

  depends_on = [
    vsphere_virtual_machine.build_citrix-adc
  ]

}