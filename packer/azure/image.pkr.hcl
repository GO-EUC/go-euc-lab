packer {
  required_plugins {
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "azure-arm" "windows" {

  #authentication
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id

  build_resource_group_name              = "rg-golab-${local.environment_abbreviations[var.environment]}-workers"
  communicator                           = local.communicator[var.os_type]
  image_offer                            = var.image_offer
  image_publisher                        = var.image_publisher
  image_sku                              = var.image_sku
  os_type                                = var.os_type
  vm_size                                = var.vm_size
  winrm_insecure                         = var.winrm_insecure
  winrm_timeout                          = var.winrm_timeout
  winrm_use_ssl                          = var.winrm_use_ssl
  winrm_username                         = var.winrm_username
  managed_image_name                     = "${local.environment_abbreviations[var.environment]}-${var.managed_image_name}-${var.delivery}-${replace(var.image_version, ".", "")}"
  managed_image_resource_group_name      = "rg-golab-${local.environment_abbreviations[var.environment]}-workers"
  virtual_network_resource_group_name    = "rg-golab-${local.environment_abbreviations[var.environment]}-vnet"
  virtual_network_name                   = "vnet-infra-${local.environment_abbreviations[var.environment]}"
  virtual_network_subnet_name            = "sn-infra-${local.environment_abbreviations[var.environment]}"
  private_virtual_network_with_public_ip = false


  shared_image_gallery_destination {
    subscription        = var.azure_subscription_id
    resource_group      = "rg-golab-${local.environment_abbreviations[var.environment]}-${var.compute_gallery_resource_group}"
    gallery_name        = "gal_packer_${local.environment_abbreviations[var.environment]}"
    image_name          = var.image_name
    image_version       = var.image_version
    replication_regions = [var.replication_regions]
  }
}

build {
  sources = ["source.azure-arm.windows"]
  provisioner "powershell" {
    script = "./scripts/windows/windows-ansible.ps1"
  }

  provisioner "ansible" {
    playbook_file = "${var.BuildSourcesDirectory}/ansible/windows-image.yml"
    user          = "packer"
    use_proxy     = false
    extra_arguments = [
      "-v",
      "-e",
      "ansible_winrm_server_cert_validation=ignore"
    ]
  }

  provisioner "powershell" {
    inline = [
      "$delivery = ${var.delivery}",
      "Write-Host \"delivery:\" $delivery",
      "if ($delivery -ne \"avd\") {exit 0 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}

dynamic "build" {
  for_each = var.delivery == "avd" ? [1] : []
  content {
    sources = ["source.azure-arm.windows"]

  }
}