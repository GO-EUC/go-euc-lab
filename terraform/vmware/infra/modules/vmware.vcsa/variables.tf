variable "vsphere_datacenter" {
  description = "VMware vSphere datacenter"
  type        = string
}

variable "vsphere_cluster" {
  description = "VMware vSphere datastore"
  type        = string
}

variable "vsphere_datastore" {
  description = "VMware vSphere datastore"
  type        = string
}

variable "vsphere_nic" {
  description = "VMware vSphere network"
  type        = string
}

variable "vsphere_nic_cidr" {
  description = "VMware vSphere datastore"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vsphere_hosts" {
  description = "VMware vSphere hosts that needs to be added (based on cidr, example: 11 will be 10.0.0.11)"
  type = set(string)
}

variable "esx_username" {
  type = string
}

variable "esx_password" {
  type = string
  sensitive = true
}