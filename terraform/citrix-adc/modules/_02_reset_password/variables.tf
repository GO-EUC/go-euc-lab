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
# New ADC password. Password needs to be reset on first logon by default.
#####

variable adc-base-newpassword {
  description = "New ADC password"
  type        = string
  default     = ""
}