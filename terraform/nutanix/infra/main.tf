terraform {
  required_version = ">= 1.2"

  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "pg" {
    schema_name = "nutanix_infra"
  }
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}
