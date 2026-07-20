/*
    DESCRIPTION:
    Microsoft Windows Server 2025 template using the Packer Builder for Nutanix (Prism Central).
    The builder boots a temporary VM from the operating system ISO in the Prism image library,
    drives the unattended installation, then captures the disk as a new library image.
*/

//  BLOCK: packer
//  The Packer configuration.

packer {
  required_version = ">= 1.8.0"
  required_plugins {
    nutanix = {
      // Pinned: 1.3.0+ uploads through the v4.2 APIs, which do not exist on
      // PC 2024.3 (the newest Prism Central deployable from Nutanix CE).
      version = "= 1.2.1"
      source  = "github.com/nutanix-cloud-native/nutanix"
    }
    windows-update = {
      version = ">= 0.14.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

//  BLOCK: locals
//  Defines the local variables.

locals {
  build_date    = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_version = formatdate("YYMM", timestamp())
  image_name    = "${var.vm_guest_os_family}-${var.vm_guest_os_name}-${var.vm_guest_os_version}-${var.vm_guest_os_edition_standard}"
}

//  BLOCK: source
//  Defines the builder configuration blocks.

source "nutanix" "windows-server" {

  // Prism Central Endpoint Settings and Credentials
  nutanix_endpoint = var.prism_central_endpoint
  nutanix_port     = var.prism_central_port
  nutanix_username = var.prism_central_username
  nutanix_password = var.prism_central_password
  nutanix_insecure = var.prism_central_insecure
  cluster_uuid     = var.nutanix_cluster_uuid


  // Virtual Machine Settings
  vm_name   = "${local.image_name}-v${local.build_version}"
  os_type   = "Windows"
  cpu       = var.vm_cpu_sockets
  core      = var.vm_cpu_cores
  memory_mb = var.vm_mem_size

  // The operating system ISO: reused from the image library by name when
  // present, otherwise downloaded from the software store URI first.
  vm_disks {
    image_type                 = "ISO_IMAGE"
    source_image_uri           = var.iso_uri
  }

  // The Nutanix VirtIO driver ISO, required by Windows setup for the SCSI disk
  // and network adapter (see the DriverPaths entry in autounattend).
  vm_disks {
    image_type       = "ISO_IMAGE"
    source_image_uri = var.virtio_iso_uri
  }

  vm_disks {
    image_type             = "DISK"
    disk_size_gb           = var.vm_disk_size
    storage_container_uuid = var.nutanix_storage_container_uuid
  }

  vm_nics {
    subnet_uuid = var.nutanix_subnet_uuid
  }

  // Removable Media Settings
  cd_files = [
    "${path.cwd}/packer/nutanix/scripts/${var.vm_guest_os_family}/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("data/autounattend.pkrtpl.hcl", {
      build_username       = var.build_username
      build_password       = var.build_password
      build_organization   = var.build_organization
      vm_inst_os_language  = var.vm_inst_os_language
      vm_inst_os_keyboard  = var.vm_inst_os_keyboard
      vm_inst_os_image     = var.vm_inst_os_image_standard_desktop
      vm_inst_os_kms_key   = var.vm_inst_os_kms_key_standard
      vm_guest_os_language = var.vm_guest_os_language
      vm_guest_os_keyboard = var.vm_guest_os_keyboard
      vm_guest_os_timezone = var.vm_guest_os_timezone
      virtio_driver_path   = var.virtio_driver_path
      network_address      = cidrhost(var.network_cidr, var.network_address)
      network_subnet       = cidrnetmask(var.network_cidr)
      network_gateway      = cidrhost(var.network_cidr, var.network_gateway)
      network_dns          = cidrhost(var.network_cidr, var.network_dns)
    })
  }

  // Boot and Provisioning Settings
  boot_type        = var.vm_boot_type
  boot_priority    = var.vm_boot_priority
  boot_wait        = var.vm_boot_wait
  boot_command     = var.vm_boot_command
  shutdown_command = var.vm_shutdown_command
  shutdown_timeout = var.common_shutdown_timeout

  // Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = var.build_username
  winrm_password = var.build_password
  winrm_port     = var.communicator_port
  winrm_use_ssl  = false
  winrm_insecure = true
  winrm_timeout  = var.communicator_timeout

  // Image Library Settings. The fixed image name is what the infra manifest
  // step and Terraform resolve; force_deregister replaces stale builds.
  image_name        = local.image_name
  image_description = "Version: v${local.build_version}\nBuilt on: ${local.build_date}\nBuilt by: HashiCorp Packer"
  force_deregister  = true
  vm_clean {
    cdrom = true
  }
}

//  BLOCK: build
//  Defines the builders to run, provisioners, and post-processors.

build {
  sources = ["source.nutanix.windows-server"]

  provisioner "powershell" {
    environment_vars = [
      "BUILD_USERNAME=${var.build_username}"
    ]
    elevated_user     = var.build_username
    elevated_password = var.build_password
    scripts           = formatlist("${path.cwd}/%s", var.scripts)
  }

  provisioner "powershell" {
    elevated_user     = var.build_username
    elevated_password = var.build_password
    inline            = var.inline
  }

  // Temporarily disabled to speed up test builds; re-enable before producing
  // production images.
  // provisioner "windows-update" {
  //   pause_before    = "30s"
  //   search_criteria = "IsInstalled=0"
  //   filters = [
  //     "exclude:$_.Title -like '*Preview*'",
  //     "exclude:$_.Title -like '*Defender*'",
  //     "exclude:$_.InstallationBehavior.CanRequestUserInput",
  //     "include:$true"
  //   ]
  //   restart_timeout = "120m"
  // }
}
