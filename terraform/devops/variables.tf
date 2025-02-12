variable "ado_url" {
  type        = string
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
    name      = string
    value     = string
    is_secret = bool
  }))
  default = []
}

variable "github_pat" {
  type        = string
  sensitive   = true
  description = "The GitHub peronsal access token"
}

variable "github_org" {
  type        = string
  description = "The GitHub org where the code is hosted, default is GO-EUC"
  default     = "go-euc"
}

variable "github_repo" {
  type        = string
  description = "The GitHub repo where the code is hosted, default is go-euc-lab"
  default     = "go-euc-lab"
}

variable "github_branch" {
  type        = string
  description = "The GitHub branch at the repo, default is main"
  default     = "main"
}