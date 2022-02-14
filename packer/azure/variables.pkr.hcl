// variable "guest_os_type" {
//   type      = string
//   
// }

locals {

    communicator = {
      Linux = "ssh"
      Windows = "winrm"      
    }

    environment_abbreviations = {
    default = "pois"
    cards   = "card"
    flowers = "flow"
    }
}

variable "environment" {
  description = ""
  type      = string
  default   = "default"
}

variable "build_resource_group_name" {
  description = ""
  type      = string
 
}

variable "client_id" {
  description = ""
  type      = string
  
}

variable "client_secret" {
  description = ""
  type      = string
  sensitive = true
}

variable "communicator" {
  description = ""
  type      = string
  sensitive = true
}

variable "image_offer" {
  description = ""
  default = "Windows-10"
  type      = string
  
}

variable "image_publisher" {
  description = ""
  default = "MicrosoftWindowsDesktop"  
  type      = string
  
}

variable "image_sku" {
  description = ""
  default = "win10-21h2-avd-g2" 
  type      = string
  
}

variable "os_type" {
  description = ""
  default   = "Windows"
  type      = string
  
}

variable "subscription_id" {
  description = ""
  type      = string
  sensitive = true
}

variable "tenant_id" {
  description = ""
  type      = bool
  sensitive = true
}

variable "vm_size" {
  description = ""
  type      = string
  default   = "Standard_D2_v2"
}

variable "winrm_insecure" {
  description = ""
  type      = bool
  default   = true
}

variable "winrm_timeout" {
  description = ""
  type      = string
  default   = "5m"  
}

variable "winrm_use_ssl" {
    description = ""
    type = bool
    default   = true
}
variable "winrm_username" {
    description = ""
    type = string
    default = "packer"
}

variable "managed_image_name" {
  description = ""
  type      = string
  default   = "build-1"  
}

variable "managed_image_resource_group_name" {
  description = ""
  type      = string
  
}

variable "virtual_network_resource_group_name" {
  description = ""
  type      = string
  
}

variable "virtual_network_name" {
  description = ""
  type      = string
  
}

variable "virtual_network_subnet_name" {
  description = ""
  type      = string
  
}

variable "private_virtual_network_with_public_ip" {
  description = ""
  default   = false
  type      = bool
  
}

variable "gallery_name" {
  description = ""
  type      = string
  
}

variable "image_name" {
  description = ""
  type      = string
  
}

variable "image_version" {
  description = ""
  type      = string
  
}

variable "replication_regions" {
  description = ""
  default   = "westeurope"
  type      = string
}

variable "resource_group" {
  description = ""
  type      = string
}