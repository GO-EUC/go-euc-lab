variable "vm_name" { type = string }
variable "vm_count" {
  type    = number
  default = 1
}
variable "vm_cpu" {
  type    = number
  default = 2
}
variable "vm_memory" {
  type    = number
  default = 4096
}
variable "vm_disk_size" {
  type    = number
  default = 100
}
variable "prism_endpoint" { type = string }
variable "prism_username" { type = string }
variable "prism_password" {
  type      = string
  sensitive = true
}
variable "prism_insecure" {
  type    = bool
  default = true
}
variable "cluster_uuid" { type = string }
variable "subnet_uuid" { type = string }
variable "image_uuid" { type = string }
variable "adapter_path" { type = string }
variable "network_addresses" {
  type = list(string)
}
variable "network_prefix" { type = number }
variable "network_gateway" { type = string }
variable "network_dns" {
  type = list(string)
}
variable "local_admin_password" {
  type      = string
  sensitive = true
}
