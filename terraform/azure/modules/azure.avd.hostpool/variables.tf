variable "azure_region" {
  type        = string
  description = "Location of the hostpool, default is west-europe"
  default     = "westeurope"
}

variable "avd_hp_rg" {
  type        = string
  description = "Name of the resourcegroup"
}

variable "avd_hp_name" {
  type        = string
  description = "Name of the hostpool"
}

variable "avd_hp_friendlyname" {
  type        = string
  description = "Friendlyname of the hostpool"
}

variable "avd_hp_validate" {
  type        = bool
  description = "Does the hostpool requires validation ? Default is set to false"
  default     = false
}

variable "avd_hp_custom_rdp_properties" {
  type        = string
  description = "Custom RDP Properties"
  default     = "audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1; "
}

variable "avd_hp_desc" {
  type        = string
  description = "Description of the hostpool"
}

variable "avd_hp_type" {
  type        = string
  description = "Type of the hostpool (personal or pooled are excepted)"
  default     = "Pooled"
}

variable "avd_hp_maxsessions" {
  type        = string
  default     =  "16"
}

variable "avd_hp_lbtype" {
  type        = string
  description = "Loadbalacing type of the hostpool if the hostpool is pooled. Choose BreadthFirst or DepthFirst"
  default     = "DepthFirst"
}

variable "avd_hp_personaldesktopassignment_type" {
  type        = string
  description = "Assignedment type of the hostpool if the hostpool type is personal Choose Dynamic of Direct"
  default     = "null"
}

