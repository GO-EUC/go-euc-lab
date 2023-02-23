terraform {

  required_version = ">= 1.2" 
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.9"
    }

    vsphere = {
      source = "hashicorp/vsphere"
      version = "~>2.2"
    }
  }

    backend "pg" { 
        schema_name = "infra"
    }
}

provider "vsphere" {
    user           = jsondecode(data.vault_kv_secret.vcsa.data_json).user
    password       = jsondecode(data.vault_kv_secret.vcsa.data_json).password
    vsphere_server = cidrhost(jsondecode(data.vault_kv_secret.network.data_json).cidr ,jsondecode(data.vault_kv_secret.vcsa.data_json).ip)

    allow_unverified_ssl = true
}

provider "vault" {
    address = var.vault_address
    token   = var.vault_token
}
