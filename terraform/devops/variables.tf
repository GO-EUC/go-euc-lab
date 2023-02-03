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
    type = list(object({
        name      = string
        value     = string
        is_secret =  bool
    }))
    default = []
    description = "Any variable that needs to be added to the Azure Devops variable group"
}