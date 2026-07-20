terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
    }
  }
}

# The VM is cloned from the Packer-built image in the Prism Central image
# library and customized at first boot through a sysprep answer file
# (computer name, static address, DNS, local administrator password).
resource "nutanix_virtual_machine" "vm" {
  count = var.vm_count

  name                 = "${var.vm_name}-${count.index + 1}"
  cluster_uuid         = var.cluster_uuid
  num_sockets          = var.vm_cpu
  num_vcpus_per_socket = 1
  memory_size_mib      = var.vm_memory
  # Must match the firmware the image was built with; the Packer templates
  # install Windows with UEFI boot.
  boot_type = var.boot_type

  guest_customization_sysprep = {
    # PREPARED: the image already contains an installed Windows; the answer
    # file only drives the specialize/oobe passes.
    install_type = "PREPARED"
    unattend_xml = base64encode(templatefile("${path.module}/sysprep.xml.tftpl", {
      computer_name  = "${var.vm_name}-${count.index + 1}"
      ip_address     = var.network_addresses[count.index]
      prefix         = var.network_prefix
      gateway        = var.network_gateway
      dns_servers    = var.network_dns
      admin_password = var.local_admin_password
    }))
  }

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = var.image_uuid
    }
    disk_size_mib = var.vm_disk_size * 1024
  }

  nic_list {
    subnet_uuid = var.subnet_uuid
  }
}
