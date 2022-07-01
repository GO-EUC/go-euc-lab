locals {
  #naming vars
  environment_abbreviations = {
    default = "pois"
    cards   = "card"
    flowers = "flow"
  }

  delivery_solutions = {
    none     = "none"
    cvads    = "cvads"
    avd      = "avd"
    horizonc = "horizonc"
  }

  #deployementname
  deploymentname = "golab"
  ad_domain_fqdn = "go.euc" #Active Directory Domain Name

  #network locals
  infra_cidr = {
    default = "10.100.0.0/16"
    cards   = "10.200.0.0/16"
    flowers = "10.220.0.0/16"
  }

  infra_subnet_cidr = {
    default = "10.100.200.0/24"
    cards   = "10.200.201.0/24"
    flowers = "10.220.202.0/24"
  }

  docker_subnet_cidr = {
    default = "10.100.124.0/24"
    cards   = "10.200.125.0/24"
    flowers = "10.220.126.0/24"
  }

  bastion_subnet_cidr = {
    default = "10.100.24.0/24"
    cards   = "10.200.25.0/24"
    flowers = "10.220.26.0/24"
  }
}

variable "azure_region" {
  type    = string
  default = "westeurope"
}

variable "delivery" {
  type      = string
  default   = "cvads"
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
  default     = "go-euc"
}

variable "devops_token" {
  type        = string
  description = "Azure DevOps perosnal access token."
  sensitive   = true
}

variable "devops_pool" {
  type        = string
  description = "Azure DevOps pool name."
}

variable "devops_agents" {
  type        = number
  description = "Azure DevOps Agents."
  default     = 3
}

variable "devops_project" {
  type        = string
  description = "Azure DevOps project name."
  default     = "NightWing"
}
