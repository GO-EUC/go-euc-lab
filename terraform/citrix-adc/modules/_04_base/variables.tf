#####
# Variables for administrative connection to the ADC
#####

variable adc-base-username {
  description = "ADC username"
  type        = string
  default     = "nsroot"
}

variable adc-base-password {
  description = "ADC password"
  type        = string
  default     = ""
}

variable adc-base-ip-mgmt-address {
  description = "ADC mgmt IP address"
  type        = string
  default     = ""
}

#####
# Variables for ADC basic configuration
#####

variable adc-base-ip {
  description = "Additional ADC IP addresses. 1 SNIP pre-filled."
  type = map
  default = {
    ipaddress = [
      "10.10.1.16"
    ]
    netmask = [
      "255.255.255.0"
    ]
    type = [
      "SNIP"
    ]
    icmp = [
      "ENABLED"
    ]
  }
}

variable adc-base-timezone {
  description = "ADC timezone"
  type        = string
  default     = "GMT+01:00-CET-Europe/Berlin"
}