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

# Number of LoadGen bot VMs (4 vCPU / 16 GiB each). The VMware lab deploys
# 10; CE clusters usually have less memory headroom, so this defaults lower.
variable "bot_count" {
  type    = number
  default = 2
}
