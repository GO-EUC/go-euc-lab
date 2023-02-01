terraform {
    required_version = ">= 1.2" 

    required_providers {
        azuredevops = {
        source  = "microsoft/azuredevops"
        version = ">=0.1.0"
        }
    }

    backend "pg" { }
}

provider "azuredevops" {
    org_service_url       = var.ado_url
    personal_access_token = var.ado_pat
}
