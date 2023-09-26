terraform {
  required_providers {
    # ACME provider for LetsEncrypt
    acme = {
      source = "vancluever/acme"
    }
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}