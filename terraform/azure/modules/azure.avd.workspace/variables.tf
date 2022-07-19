variable "azure_region" {
  type        = string
  description = "Azure region of deployment."
  default     = "westeurope"
}

variable "avd_workspace_name" {
  type        = string
  description = "Specifies the name of the workspace."
}

variable "avd_rg_name" {
  type        = string
  description = "The name of the resource group in which to create the workspace."
}

variable "prefix" {
  type        = string
  description = "prefix used for the workspace"
}

variable "tags" {
  type        = map(string)
  description = "Tags for the workspace"
  default     = {}
}

