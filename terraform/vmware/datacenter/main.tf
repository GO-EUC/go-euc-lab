terraform {
    required_version = ">= 1.2"

    required_providers {
        vault = {
            source = "hashicorp/vault"
            version = ">= 3.12.0"
        }

        vsphere = {
            source = "hashicorp/vsphere"
            version = "~>2.2"
        }
    }

    backend "pg" { 
        schema_name = "datacenter"
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


