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
# ADC GW vServer
#####

variable "adc-gw-vserver" {
  type = map
  default = {

    name = [
      "YourGWvServerName"
    ]
    servicetype = [
      "SSL"
    ]
    ipv46 = [
      "YourGWvServerIP"
    ]
    port = [
      YourGWvServerPort
    ]
    dtls = [
      "YourGWvServerDTLSSetting"
    ]
    tcpprofilename = [
      "YourTCPProfileName"
    ]
    httpprofilename = [
      "YourhttpProfileName"
    ]
    appflowlog = [
      "YourAppFlowLoggingSetting"
    ]

  }

}

#####
# ADC GW vServer STA Bindings
#####

variable "adc-gw-vserver-staserverbinding" {
  type = map
  default = {

    name = [
      "YourGWvServerName"
    ]
    staserver = [
      "YourFirstSTAServer",
      "YourSecondSTAServer"
    ]
    staaddresstype = [
      "YourFirstSTAServerAddresstype",
      "YourSecondSTAServerAddresstype"
    ]

  }

}

#####
# ADC GW vServer VPN Session Policy Bindings
#####

variable "adc-gw-vserver-vpnsessionpolicybinding" {
  type = map
  default = {

    name = [
      "YourGWvServerName",
      "YourGWvServerName"
    ]
    policy = [
      "sess_prof_sf_receiverweb",
      "sess_prof_sf_receiver"
    ]
    priority = [
      "10",
      "20"
    ]

  }

}