
variable "project_name" {
  type    = string
  default = "go"
}

variable "azure_subscription_id" {
  type      = string
  sensitive = true
}

variable "azure_client_id" {
  type      = string
  sensitive = true
}

variable "azure_client_secret" {
  type      = string
  sensitive = true
}

variable "azure_tenant_id" {
  type      = string
  sensitive = true
}

variable "devops_orgname" {
  type        = string
  description = "Azure DevOps oranization name."
}

variable "devops_token" {
  type        = string
  description = "Azure DevOps perosnal access token."
  sensitive   = true
}

variable "devops_agents" {
  type        = number
  description = "Azure DevOps Agents."
  default     = 3
}

variable "devops_project" {
  type        = string
  description = "Azure DevOps project name."
  default = "GO-EUC Lab"
}

variable "github_pat" {
  type        = string
  description = "GitHub personal access token."
  sensitive   = true
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