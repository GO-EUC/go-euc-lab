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

variable "vm_cpu" {
  description = "Amount of VM vCPUs"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Amount of VM memory"
  type        = number
  default     = 4096
}

variable "vm_disks" {
  description = "Disks needs to be added"
  type = list(object({
    unit_number = number
    label       = string
    size        = number
  }))
  default = [{
    unit_number = 0
    label       = "disk0"
    size        = 64
  }]
}

variable "firmware" {
  description = "Boot firmware of the VM, Terraform default is bios, this case needs to be efi."
  type        = string
  default     = "efi"
}

variable "vm_guest_id" {
  description = "GuestID"
  type        = string
  sensitive   = false
  default     = "windows2019srv_64Guest"
}

variable "local_admin" {
  description = "Local administrator"
  type        = string
  sensitive   = false
  default     = "Administrator"
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain to join"
  type        = string
  sensitive   = false
}

variable "domain_admin" {
  description = "Domain administrator to join to the domain"
  type        = string
  sensitive   = false
}

variable "domain_admin_password" {
  description = "Domain administrator password to join to the domain"
  type        = string
  sensitive   = true
}

variable "network_address" {
  description = "Static network address"
  type        = string
  default     = ""
  sensitive   = false
}

variable "network_netmask" {
  description = "Network subnetmask"
  type        = number
  default     = 24
  sensitive   = false
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
  sensitive   = false
  default     = ""
}

variable "virtual_network_portgroup_name" {
  description = "The name of the VMware portgroup"
  type        = string
  sensitive   = false
}

variable "vsphere_datacenter" {
  description = "The name of the VMware datacenter to deploy resources"
  type        = string
  sensitive   = false
}

variable "vsphere_datastore" {
  description = "The name of the VMware datastore to deploy resources"
  type        = string
  sensitive   = false
}

variable "vsphere_cluster" {
  description = "The name of the VMware vsphere cluster to deploy resources"
  type        = string
  sensitive   = false
}

variable "vsphere_source_template" {
  description = "The name of the Virtual Machine of template to use as source"
  type        = string
  sensitive   = false
}

