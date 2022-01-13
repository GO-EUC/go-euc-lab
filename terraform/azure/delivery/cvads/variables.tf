variable "location" {
    type = string
}

variable "workspace" {
  type = string
}

variable "deployment_name" {
    type = string
}

variable "azure_vnet_name" {
    type = string
}

variable "azure_vnet_resource_group_name" {
    type = string
}

variable "azure_subnet_name" {
    type = string
}

variable "local_admin_password" {
    type      = string
    sensitive = true
}

variable "local_admin" {
    type      = string
}