locals {
  delivery_solutions = {
    none    = "none"
    cvad    = "cvad"
    horizon = "horizon"
  }
}

variable "delivery" {
  description = "Delivery model"
  type        = string
}

variable "root_path" {
  description = "The root path of the repository, this is required to collect the packer manifests."
  type        = string
}

variable "vsphere_deploy" {
  description = "Switch to deploy the default configuraiton to vSphere, is required when the VCSA deployment is used/"
  type        = bool
  default     = false
}
variable "vsphere_user" {
  description = "VMware vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "VMware vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "VMware vSphere server"
  type        = string
}

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
  description = "VMware vSphere network cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vsphere_hosts" {
  description = "VMware vSphere hosts that needs to be added (based on cidr, example: 11 will be 10.0.0.11)"
  type        = set(string)
}

variable "esx_username" {
  description = "ESXi host username"
  type        = string
  default     = "root"
}

variable "esx_password" {
  description = "ESXi host password"
  type        = string
  sensitive   = true
}

variable "domain_fqdn" {
  description = "FQDN domain name"
  type        = string
  default     = "GO.EUC"
}

variable "domain_admin" {
  description = "Domain administrator name"
  type        = string
  default     = "Administrator"
}

variable "domain_admin_password" {
  description = "Domain administrator password"
  type        = string
  sensitive   = true
}

variable "local_admin_password" {
  description = "Password for the local admin"
  type        = string
  sensitive   = true
}
