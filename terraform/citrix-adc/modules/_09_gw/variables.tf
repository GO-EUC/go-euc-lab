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
      "YourGWvServerPort"
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

#####
# ADC Authentication LDAP Action
#####

variable "adc-gw-vserver-authenticationldapaction" {
  type = map
  default = {

    name = [
      "auth_act_secureldap_goeuc.local"
    ]
    servername = [
      "9.9.9.9"
    ]
    ldapBase = [
      "dc=goeuc,dc=local" 
    ]
    ldapBindDn = [
      "svc_ldap@goeuc.local"
    ]
    ldapBindDnPassword = [
      ""
    ]
    ldapLoginName = [
      "sAMAccountName"
    ]
    groupAttrName = [
      "memberOf"
    ]    
    subAttributeName = [
      "cn"
    ]
    ssoNameAttribute = [
      "cn"
    ]
    secType = [
      "TLS"
    ]
    passwdChange = [
      "ENABLED"
    ]

  }
}

#####
# ADC Authentication LDAP Policy
#####

variable "adc-gw-vserver-authenticationldappolicy" {
  type = map
  default = {

    name = [
      "auth_pol_secureldap_goeuc.local"
    ]
    rule = [
      "ns_true"
    ]
    reqaction = [
      "auth_act_secureldap_goeuc.local"
    ]

  }
}

#####
# ADC Authentication LDAP Policy GW vServer Binding
#####

variable "adc-gw-vserver-authenticationldappolicy_binding" {
  type = map
  default = {

    name = [
      "YourGWvServerName"
    ]
    policy = [
      "auth_pol_secureldap_goeuc.local"
    ]
    priority = [
      "100"
    ]
    bindpoint = [
      "REQUEST"
    ]
  }
}