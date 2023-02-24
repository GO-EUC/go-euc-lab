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
# ADC Loadbalancing Server
#####

variable "adc-lb-server" {
  description = "ADC Loadbalancing server"
  type = map
  default = {
    name = [
      "YourFirstServer",
      "YourSecondServer",
      "YourThirdServer"
    ]
    ip = [
      "YourFirstServerIP",
      "YourSecondServerIP",
      "YourThirdServerIP"
    ]
  }

}

#####
# ADC Loadbalancing Servicegroups
#####

variable adc-lb-servicegroup {
  description = "ADC Servicegroups"
  type = map
  default = {
    servicegroupname = [
      "YourFirstServicegroup",
      "YourSecondServicegroup",
      "YourThirdServicegroup"

    ]
    servicetype = [
      "YourFirstServicegroupType",
      "YourSecondServicegroupType",
      "YourThirdServicegroupType"

    ]
  }
}

#####
# ADC Loadbalancing Servicegroup-Server-Bindings
#####

variable adc-lb-sg-server-binding {
  description = "ADC Service Group Server Bindings"
  type = map
  default = {
    servicegroupname = [
      "YourFirstServicegroup",
      "YourSecondServicegroup",
      "YourThirdServicegroup"
    ]
    servername = [
      "YourFirstServer",
      "YourSecondServer",
      "YourThirdServer"
    ]
    port = [
      "YourFirstPort",
      "YourSecondPort",
      "YourThirdPort"
    ]
  }
}

#####
# ADC Loadbalancing vServer - Type SSL
#####

variable adc-lb-vserver-ssl{
  description = "ADC LB vServer - Type SSL"
  type = map
  default = {
    name = [
      "YourFirstLBvServerSSL",
      "YourSecondLBvServerSSL"
    ]
    servicetype = [
      "SSL",
      "SSL"
    ]
    sslprofile = [
      "YourFirstSSLProfile",
      "YourSecondSSLProfile"
    ]
    ipv46 = [
      "YourFirstIP",
      "YourSecondIP"
    ]
    port = [
      "YourFirstPort",
      "YourSecondPort"
    ]
    lbmethod = [
      "YourFirstLBMethod",
      "YourSecondLBMethod"
      ]
    persistencetype = [
      "YourFirstPersistenceType",
      "YourSecondPersistenceType"
      ]
    timeout = [
      "YourFirstPersistenceTimeout",
      "YourSecondPersistenceTimeout"
      ]
  }
}

#####
# ADC Loadbalancing vServer - Type DNS
#####

variable adc-lb-vserver-dns{
  description = "ADC LB vServer - Type DNS"
  type = map
  default = {
    name = [
      "YourFirstLBvServerDNS"
    ]
    servicetype = [
      "DNS"
    ]
    ipv46 = [
      "YourFirstIP"
    ]
    port = [
      "YourFirstPort"
    ]
    lbmethod = [
      "YourFirstLBMethod"
    ]
    persistencetype = [
      "YourFirstPersistenceType"
    ]
    timeout = [
      "YourFirstPersistenceTimeout"
    ]
  }
}

#####
# ADC Loadbalancing vServer-Servicegroup-Bindings
#####

variable adc-lb-vserver-sg-binding {
  description = "ADC vServer Service Group Binding"
  type = map
  default = {
    name = [
      "YourFirstLBvServerSSL",
      "YourSecondLBvServerSSL",
      "YourFirstLBvServerDNS"
    ]
    servicegroupname = [
      "YourFirstServicegroupSSL",
      "YourSecondServicegroupSSL",
      "YourFirstServicegroupDNS"
    ]
  }
}