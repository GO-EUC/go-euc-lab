terraform {
  required_version = ">= 1.0.0"
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
      version = ">= 1.17.0"
    }
    acme = {
      source = "vancluever/acme"
      version = ">= 2.10.0"
    }
  }
}

provider "citrixadc" {
  endpoint = var.adc-base-ip-mgmt-address
  username = var.adc-base-username
  password = var.adc-base-password

  # If you have a self-signed cert
  insecure_skip_verify = true
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  #server_url = "https://acme-v02.api.letsencrypt.org/directory"
}