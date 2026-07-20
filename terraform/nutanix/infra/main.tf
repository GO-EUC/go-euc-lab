terraform {
  required_version = ">= 1.2"

  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
    random = {
      source = "hashicorp/random"
    }
    nutanix = {
      source = "nutanix/nutanix"
      # 1.9.x targets the Prism Central v3 API, which matches PC 2024.3 (the
      # newest release deployable from Nutanix CE).
      version = "= 1.9.5"
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

provider "nutanix" {
  endpoint = local.prism_central.endpoint
  username = local.prism_central.username
  password = local.prism_central.password
  insecure = lower(tostring(local.prism_central.insecure)) == "true"
  port     = 9440
}
