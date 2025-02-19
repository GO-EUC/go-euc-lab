variable "root_path" {
  description = "The root path of the repository, this is required to collect the packer manifests."
  type        = string
}

variable "windows_template" {
  description = "The name of the template, such as windows-11 or server-2025."
  type        = string
  default     = "windows-11"
}

variable "delivery" {
  description = "The delivery method, citrix, omnissa, rdsh, parallels."
  type        = string
  default     = "citrix"
}

variable "build_name" {
  description = "The name of the build machine."
  type        = string
}

variable "build_vcpu" {
  description = "The amount of vCPU, default 4"
  type        = number
  default     = 4
}

variable "build_memory" {
  description = "The amount of memory, default 8GB"
  type        = number
  default     = 8192
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

variable "ansible_playbook" {
  description = "The playbook that needs to be executed, make sure to use the relative path."
  type        = string
}