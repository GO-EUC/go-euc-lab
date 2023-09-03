terraform {
  required_version = ">= 1.3.5"
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
      version = ">= 1.32.0"
    }
  }
}