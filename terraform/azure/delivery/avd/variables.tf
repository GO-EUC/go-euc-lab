variable "deployment_name" {
  type        = string
  description = "Name of the deployement. I.e. GOLAB"
}

variable "workspace" {
  type        = string
  description = "Name of the Terraform workspace. I.e. POIS, FLOW, CARD"
}

variable "location" {
  type        = string
  description = "Name of the Location"
  default     = "West Europe"
}

variable "sessionhost_amount" {
  type        = number
  description = "Amount of session hosts"
  default     = 2
}

variable "sessionhost_sku" {
  type        = string
  description = "IaaS VM SKU Size for Session Host"
  default     = "Standard_D4ds_v4"
}

variable "azure_vnet_name" {
  description = "Name of vNET"
  type        = string
}

variable "azure_vnet_resource_group_name" {
  description = "Name of vnet ResourceGroup"
  type        = string
}

variable "azure_subnet_name" {
  description = "Name of subnet"
  type        = string
}

variable "local_admin" {
  description = "Local administrator"
  type        = string
  default     = "lcladmin"
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
}

variable "AD_joinuser" {
  description = "UPN for user to join domain"
  type        = string
}

variable "AD_joinpassword" {
  description = "Password for domain join"
  type        = string
  sensitive   = true
}

variable "AD_domain" {
  description = "Domain to join"
  type        = string
}

variable "AD_oupath" {
  description = "Path to the OU in AD Domain OU= format"
  type        = string
}

variable "avd_users" {
  description = "Users with access to the AVD Desktop"
  default = [
    "patrick@vandenborn.it",
    "kelly@vandenborn.it"
  ]
}


