resource "vsphere_virtual_machine" "vm" {
  count            = var.vm_count
  name             = "${var.vm_name}-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.vm_cpu
  memory   = var.vm_memory
  guest_id = var.vm_guest_id

  firmware = var.firmware

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  dynamic "disk" {
    for_each = var.vm_disks
    content {
      unit_number = disk.value.unit_number
      label       = disk.value.label
      size        = disk.value.size
    }
  }

  dynamic "clone" {
    for_each = var.network_address != "" ? [1] : []
    content {
      template_uuid = data.vsphere_virtual_machine.template.id

      customize {
        timeout = 30

        windows_options {
          computer_name  = "${var.vm_name}-${count.index + 1}"
          admin_password = var.local_admin_password
        }

        network_interface {
          ipv4_address = var.network_address
          ipv4_netmask = var.network_netmask
          dns_server_list = var.network_dns_list
        }

        ipv4_gateway = var.network_gateway
      }
    }
  }

  dynamic "clone" {
    for_each = var.network_address == "" ? [1] : []
    content {
      template_uuid = data.vsphere_virtual_machine.template.id

      customize {
        timeout = 30

        windows_options {
          computer_name  = "${var.vm_name}-${count.index + 1}"
          admin_password = var.local_admin_password
        }

        network_interface {}
      }
    }
  }

  lifecycle {
    ignore_changes = [ clone ]
  }
}