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
        schema_name = "vcsa"
    }
}

provider "vault" {
    address = var.vault_address
    token   = var.vault_token
}