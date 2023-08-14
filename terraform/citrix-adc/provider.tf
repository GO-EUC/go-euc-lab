locals {
  ip-mgmt-address = "http://${var.vm.ip}"
}

terraform {
  required_version = ">= 1.3.5"
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
      version = ">= 1.31.0"
    }
    acme = {
      source = "vancluever/acme"
      version = ">= 2.13.1"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere.user
  password       = var.vsphere.password
  vsphere_server = var.vsphere.server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

provider "citrixadc" {
  endpoint = local.ip-mgmt-address
  username = var.adc-base.username
  password = var.adc-base.password

  # If you have a self-signed cert
  insecure_skip_verify = true
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  #server_url = "https://acme-v02.api.letsencrypt.org/directory"
}