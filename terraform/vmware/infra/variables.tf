variable "root_path" {
  description = "The root path of the repository, this is required to collect the packer manifests."
  type        = string
}

variable "citrix_cloud" {
  type    = bool
  default = false
}

variable "citrix_vad" {
  type    = bool
  default = false
}

variable "vmware_horizon" {
  type    = bool
  default = false
}

variable "network_list" {
  description = "List of available CIDR based network address"
  type        = list(number)
}

variable "vsphere_datacenter" {
  description = "VMware vSphere datacenter"
  default     = "GO"
  type        = string
}

variable "vsphere_cluster" {
  description = "VMware vSphere datastore"
  default     = "Infra"
  type        = string
}

variable "domain_admin" {
  description = "Domain administrator name"
  type        = string
  default     = "Administrator"
}

variable "vault_address" {
  description = "The vault address in format: http://vault.go.euc:8200"
  type        = string
}

variable "vault_token" {
  description = "The vault token that will be used for authtentication"
  type        = string
  sensitive   = true
}
