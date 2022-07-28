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

variable adc-base-ip {
  description = "Additional ADC IP addresses"
  type = map
  default = {
    ipaddress = [
      ""
    ]
    netmask = [
      ""
    ]
    type = [
      ""
    ]
    icmp = [
      ""
    ]
  }
}

#variable adc-base-timezone {
#  description = "ADC timezone"
#  type        = string
#  default     = ""
#}