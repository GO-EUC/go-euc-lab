terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

# Target non default partition
provider "citrixadc" {
  endpoint   = var.logon_information.host
  username   = var.logon_information.username
  password   = var.logon_information.password
  do_login   = true

# Allow connection upon invalid certificate
  insecure_skip_verify = true

}