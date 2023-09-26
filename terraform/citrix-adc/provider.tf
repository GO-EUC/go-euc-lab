terraform {
  required_providers {
    # Provider for Citrix NetScaler
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

# Target non default partition
provider "citrixadc" {
  endpoint = var.logon_information.host
  username = var.logon_information.username
  password = var.logon_information.password
  do_login = true

  # Allow connection upon invalid certificate
  insecure_skip_verify = true

}

provider "vsphere" {
  user           = var.vsphere.user
  password       = var.vsphere.password
  vsphere_server = var.vsphere.server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
