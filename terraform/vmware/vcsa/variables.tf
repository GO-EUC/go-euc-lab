variable "vsphere_deploy" {
  description = "Switch to deploy the VCSA applicance"
  type        = bool
  default     = false
}

variable "esx_user" {
  description = "ESXi username"
  type        = string
  default     = "root"
}

variable "esx_password" {
  description = "ESXi password"
  type        = string
  sensitive   = true
}

variable "esx_hosts" {
  description = "ESXi hosts, please note by default the first will be selected (based on cidrhost, example: 11 will be 10.0.0.11)"
  type        = list(number)
}

variable "esx_datastore" {
  description = "ESXi datastore"
  type        = string
}

variable "esx_nic" {
  description = "ESXi network"
  type        = string
}

variable "vsphere_source" {
  description = "Source of the vSphere application insallation (for windows: [source:vcsa-cli-installer\\win32\\vcsa-deploy.exe], for linux: [source:/vcsa-cli-installer/lin64/vcsa-deploy])"
  type        = string
  default     = "vcsa"
}

variable "vsphere_version" {
  description = "Version of the vSphere applications source (supported version 7.x.x)"
  type        = string
  default     = "7.0.3"
}

variable "vsphere_name" {
  description = "VM name of the VCSA applicance"
  type        = string
  default     = "vcsa"
}

variable "vsphere_password" {
  description = "VMware vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_nic_cidr" {
  description = "VMware vSphere network cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vsphere_ip" {
  description = "VCSA appliance ip (based on cidrhost, example: 5 will be 10.0.0.5)"
  type        = number
  default     = 5
}

variable "vsphere_gateway" {
  description = "VCSA gateway ip (based on cidrhost, example: 1 will be 10.0.0.1)"
  type        = number
  default     = 1
}

variable "vsphere_dns" {
  description = "VCSA gateway ip (based on cidrhost, example: 1 will be 10.0.0.1)"
  type        = number
  default     = 1
}

variable "vsphere_ntp" {
  description = "Public time NTP services"
  type        = string
  default     = "nl.pool.ntp.org"
}