variable adc-base-username {

  description = "ADC username"
  default = "nsroot"
  
}

variable adc-base-password {

  description = "ADC password"
  default = ""

}

variable adc-base-ip-mgmt-address {

  description = "ADC mgmt IP address"
  default = ""

}

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

variable "adc-gw-vserver-vpnsessionpolicybinding" {
  type = map
  default = {

    name = [
      "YourGWvServerName",
      "YourGWvServerName"
    ]
    policy = [
      "YourReceiverWebPolicy",
      "YourReceiverPolicy"
    ]
    priority = [
      "YourReceiverWebPriority",
      "YourReceiverPriority"
    ]

  }

}