
variable "vm_name" {
  description = "Name of VM"
  type        = string
  sensitive   = false
}

variable "vm_count" {
  description = "Amount of VM's"
  type        = number
  default     = 1
}

variable "azure_vm_sku" {
  description = "SKU of Virtual Machine"
  type        = string
  default     = "Standard_D2s_v4"

}

variable "azure_location" {
  description = "Azure location. ie. westeurope"
  type        = string
  sensitive   = false
  default     = "westeurope"
}

variable "azure_resource_group_name" {
  description = "Azure resourcegroup"
  type        = string
  sensitive   = false
}

variable "azure_fault_domain_count" {
  description = "Azure fault domain, check region documentation"
  type        = string
  default     = "3"
}

variable "azure_update_domain_count" {
  description = "Azure update domain, check region documentation"
  type        = string
  default     = "5"
}

variable "azure_vnet_name" {
  description = "Name of vNET"
  type        = string
  sensitive   = false
}

variable "azure_vnet_resource_group_name" {
  description = "Name of ResourceGroup"
  type        = string
  sensitive   = false
}

variable "azure_subnet_name" {
  description = "Name of subnet"
  type        = string
  sensitive   = false
}

variable "azure_image_sku" {
  description = "SKU for Windows Image"
  type        = string
  default     = "2022-Datacenter"

}

variable "azure_mananaged_disk_type" {
  description = "Type of managed disk"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "local_admin" {
  description = "Local administrator"
  type        = string
  sensitive   = false
  default     = "lcladmin"
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
}

variable "azure_vm_timezone" {
  description = "Time zone of Windows VM https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/"
  type        = string
  default     = "W. Europe Standard Time"
}

variable "managed_disks" {
  description = "Add managed disks to the VM for data storage"
  type = list(object({
    name = string
    disk_size_gb = number
    storage_account_type = string
    create_option = string
  }))
  default = []
}