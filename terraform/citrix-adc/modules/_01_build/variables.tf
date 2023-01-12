#####
# vSphere configuration variables
#####

variable "vsphere_server" {
  description   = "vSphere server for the environment"
  type          = string
  default       = ""
}

variable "vsphere_user" {
  description   = "vSphere admin username"
  type          = string
  default       = ""
}

variable "vsphere_password" {
  description   = "vSphere admin password"
  type          = string
  default       = ""
}

variable "vsphere_datacenter" {
  description   = "vSphere datacenter"
  type          = string
  default       = ""
}

variable "vsphere_datastore" {
  description   = "vSphere datastore to deploy"
  type          = string
  default       = ""
}

variable "vsphere_resourcepool" {
  description   = "vSphere resource pool"
  type          = string
  default       = ""
}

#####
# ADC VM configuration variables
#####

variable "vm_network" {
  description   = "vSphere network for ADC VM"
  type          = string
  default       = ""
}

variable "vm_ip" {
  description   = "IP of ADC VM"
  type          = string
  default       = ""
}

variable "vm_gateway" {
  description   = "Gateway of ADC VM"
  type          = string
  default       = ""
}

variable "vm_netmask" {
  description   = "Subnet mask of the ADC VM network"
  type          = string
  default       = ""
}

variable "vm_name" {
  description   = "Name for ADC VM"
  type          = string
  default       = ""
}

variable "vm_folder" {
  description   = "Folder path to place ADC VM"
  type          = string
  default       = null
}

variable "vm_host" {
  description   = "Host to import OVF to"
  type          = string
  default       = ""
}

variable "vm_ovf" {
  description   = "OVF file to deploy"
  type          = string
  default       = ""
}

variable "vm_mac" {
  description   = "Static ADC VM MAC address"
  type          = string
  default       = ""
}