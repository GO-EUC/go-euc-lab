variable "root_path" {
  type        = string
  description = "Repository root used to locate image manifests and Prism scripts."
}

variable "network_list" {
  type        = list(number)
  description = "Available host offsets from the platform-neutral network planner."
}

variable "vault_address" {
  type = string
}

variable "vault_token" {
  type      = string
  sensitive = true
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
