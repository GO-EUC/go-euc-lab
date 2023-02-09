packer {
    required_plugins {
        vmware = {
        version = ">= 1.0.7"
        source = "github.com/hashicorp/vmware"
        }
    }
}

locals {
    data_source_content = {
    "/meta-data" = file("${abspath(path.root)}/data/meta-data")
    "/user-data" = templatefile("${abspath(path.root)}/data/user-data.pkrtpl.hcl", {
        build_name               = var.vm_name
        build_username           = var.build_username
        build_password           = var.build_password
        build_password_encrypted = var.build_password_encrypted
        vm_guest_os_language     = var.vm_guest_os_language
        vm_guest_os_keyboard     = var.vm_guest_os_keyboard
        vm_guest_os_timezone     = var.vm_guest_os_timezone
        network_address          = "${cidrhost(var.network_cidr, var.network_address)}/${split("/", var.network_cidr)[1]}"
        network_subnet           = cidrnetmask(var.network_cidr)
        network_gateway          = cidrhost(var.network_cidr, var.network_gateway)
        network_dns              = cidrhost(var.network_cidr, var.network_dns)
    })
    }
    data_source_command = "ds=\"nocloud\""
}

source "vmware-iso" "docker" {
    iso_url      = var.iso_url
    iso_checksum = var.iso_checksum
    communicator = "ssh"
    
    ssh_host     = cidrhost(var.network_cidr, var.network_address)
    ssh_username = var.build_username
    ssh_password = var.build_password
    ssh_port     = 22
    ssh_timeout  = "30m"
    
    remote_type         = "esx5"
    remote_host         = var.esx_host
    remote_username     = var.esx_username
    remote_password     = var.esx_password
    vnc_over_websocket  = var.esx_vnc_over_websocket
    insecure_connection = var.esx_insecure_connection

    shutdown_command = "echo ${var.build_password} | sudo -S -E shutdown -P now"

    skip_export     = true
    keep_registered = true
    headless = true

    vm_name              = var.vm_name
    guest_os_type        = var.vm_guest_os_type
    version              = var.vm_version
    cpus                 = var.vm_cpus
    memory               = var.vm_memory
    remote_datastore     = var.vm_disk_datastore
    disk_size            = var.vm_disk_size
    disk_type_id         = var.vm_disk_type_id
    network_name         = var.vm_network_name
    network_adapter_type = var.vm_network_adapter_type

    cd_content = local.data_source_content
    cd_label   = "cidata"

    boot_wait    = "5s"
    boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ${local.data_source_command}",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
    ]
}

build {
    sources = ["sources.vmware-iso.docker"]

    provisioner "shell" {
        script = "${abspath(path.root)}/scripts/docker.sh"
    }
}