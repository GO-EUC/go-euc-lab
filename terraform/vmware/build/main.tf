terraform {

  required_version = ">= 1.2"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~>2.11.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = ">= 4.6.0"
    }

    ansible = {
      source = "ansible/ansible"
      version = "~>1.3.0"
    }
  }

  backend "local" {
  }
}

provider "vsphere" {
  user           = jsondecode(data.vault_kv_secret.vcsa.data_json).user
  password       = jsondecode(data.vault_kv_secret.vcsa.data_json).password
  vsphere_server = cidrhost(jsondecode(data.vault_kv_secret.network.data_json).cidr, jsondecode(data.vault_kv_secret.vcsa.data_json).ip)

  allow_unverified_ssl = true
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}
