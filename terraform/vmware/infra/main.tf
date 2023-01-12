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

  # backend "azurerm" {
  # }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  allow_unverified_ssl = true
}
