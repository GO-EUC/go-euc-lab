variable "ado_url" {
    type    = string
    description = "The default Azure DevOps url, like https://dev.azure.com/orgname"
}

variable "ado_pat" {
    type        = string
    sensitive   = true
    description = "The Azure DevOp PAT (Personal Access Token)"
}

variable "ado_variables" {
  description = "List of variables for Azure DevOps"
  type = list(object({
    name         = string
    value        = optional(string)
    secret_value = optional(string)
    is_secret    = optional(bool)
  }))
    default = []
}