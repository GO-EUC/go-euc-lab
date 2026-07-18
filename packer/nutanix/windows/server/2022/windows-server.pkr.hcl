packer {
  required_plugins {
    nutanix = {
      source  = "github.com/nutanix-cloud-native/nutanix"
      version = ">= 1.1.8"
    }
  }
}

variable "nutanix_endpoint" { type = string }
variable "nutanix_username" { type = string }
variable "nutanix_password" {
  type      = string
  sensitive = true
}
variable "nutanix_cluster" { type = string }
variable "nutanix_subnet" { type = string }
variable "source_image_name" { type = string }
variable "image_name" {
  type    = string
  default = "windows-server-2022-standard"
}

# The official builder is retained for Element releases that expose the required
# APIs. The pipeline probes compatibility first and otherwise uses the Prism
# Element adapter to import a prepared disk image.
source "nutanix" "windows_server_2022" {
  nutanix_endpoint = var.nutanix_endpoint
  nutanix_username = var.nutanix_username
  nutanix_password = var.nutanix_password
  nutanix_insecure = true
  cluster_name     = var.nutanix_cluster
  os_type          = "Windows"

  vm_disks {
    image_type        = "DISK_IMAGE"
    source_image_name = var.source_image_name
  }

  vm_nics {
    subnet_name = var.nutanix_subnet
  }

  image_name       = var.image_name
  force_deregister = true
  communicator     = "winrm"
  winrm_username   = "Administrator"
  winrm_insecure   = true
  winrm_use_ssl    = true
}

build {
  sources = ["source.nutanix.windows_server_2022"]

  post-processor "manifest" {
    output     = "manifests/windows-server-2022-standard.json"
    strip_path = true
  }
}
