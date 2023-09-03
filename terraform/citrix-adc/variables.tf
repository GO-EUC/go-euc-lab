#####
# vSphere configuration variables
#####
variable vsphere {
  type = map
  description = "[Required] vSphere Configuration Variables"
  default = {
    server       = "192.168.1.4"
    user         = "administrator@vsphere.local"
    password     = ""
    datacenter   = "YourEnvironment"
    host         = "192.168.1.3"
    datastore    = "VM"
    network      = "vSwitch_Internal"
    timezone     = 020
    resourcepool = "YourEnvironment-tf"
  }
}
#####
# ADC VM configuration variables
#####
variable vm {
  type = map
  description = "[Required] NetScaler VM Variables"
  default = {
    ovf     = "YourOVFFile"
    network = "vSwitch_Internal"
    mac     = "00:00:00:aa:bb:cc"
    ip      = "192.168.1.15"
    gateway = "192.168.1.1"
    netmask = "255.255.255.0"
    name    = "adc-01"
  }
}

#####
# ADC base variables
#####
variable adc-base {
  type = map
  description = "[Required] NetScaler System Variables"
  default = {
    username        = "nsroot"
    oldpassword     = "nsroot"
    password        = "NewSecurePassword"
    hostname        = "adc-01"
    environmentname = "YourEnvironment"
    timezone        = "GMT+01:00-CET-Europe/Berlin"
    fqdn_int        = "domain.local"
    fqdn_ext        = "YourEnvironment.YourDomain.YourTLD"
  }
}

variable adc-snip {
  type = map
  description = "NetScaler SubnetIP Variables"
  default = {
    ip      = "192.168.1.16"
    netmask = "255.255.255.0"
    icmp    = "ENABLED"
  }
}

variable adc-license {
  type = map
  description = "NetScaler license variables | Default Express license: https://docs.netscaler.com/en-us/citrix-adc/current-release/licensing/citrix-adc-licensing-overview.html "
  default = {
    filename     = "your_adc_license.lic"
    filecontent  = "sources/license/your_adc_license.lic"
  }
}

#####
# ADC LetsEncrypt LB configuration variables
#####
variable adc-letsencrypt-lb {
  type = map
  description = "[Required] LetsEncrypt LoadBalancer configuration variables"
  default = {
    backend-ip  = "192.168.1.25"
    frontend-ip = "192.168.1.17"
    servicetype = "TCP"
    port        = "80"
  }
}

#####
# ADC LetsEncrypt configuration variables
#####
variable adc-letsencrypt-certificate {
  type = map
  description = "[Required] LetsEncrypt Configuration variables"
  default = {
    private_key_algorithm      = "RSA"
    private_key_rsa_bits       = "4096"
    private_key_ecdsa_curve    = "P224"
    registration_email_address = "you@something.com"
    common_name                = "citrix"
  }
}

variable adc-letsencrypt-certificate-san {
  type    = list
  default = [
    "citrix.YourEnvironment.YourDomain.YourTLD"
  ]
}
#####
# ADC LB variables
#####
variable adc-lb-srv {
  type = map
  description = "[Required] NetScaler Basic LoadBalancing Virtual Server variables"
  default = {
    name = [
    "citrix-ctrl-01",
		"dc-01"
    ]
    ip = [
      "192.168.1.101",
      "192.168.1.10"
	  ]
  }
}

variable adc-lb {
  type = map
  default = {
    name = [
		"sf",
    "dc",
		"dc"
    ]
    type = [
		"http",
    "DNS",
		"TCP"
    ]
    port = [
      "80",
      "53",
      "389"
    ]
    backend-server = [
      "citrix-ctrl-01",
      "dc-01",
      "dc-01"
    ]
    lb-type = [
      "content-switch",
      "direct",
      "direct"
    ]  
  }
}

variable adc-lb-generic {
  type = map
  default = {
    lbmethod         = "LEASTCONNECTION"
    persistencetype  = "SOURCEIP"
    timeout          = "2"
    sslsnicert       = "false"
  }
}

#####
# ADC Citrix Gateway variables
#####
variable adc-gw {
  type = map
  description = "[Required] ADC Citrix Gateway variables"
  default = {
    name                 = "citrix"
    staserver            = "citrix-ctrl-01"
    dnsvservername       = "lb_vs_dc.domain.local_DNS_53"
    authenticationpolicy = "auth_pol_ldap_domain.local"
    citrix-backend       = "http://citrix-ctrl-01.domain.local/Citrix/StoreWeb/"
    servicetype          = "SSL"
    ip                   = "0.0.0.0"
    port                 = 0
    dtls                 = "OFF"
    appflowlog           = "DISABLED"
    staaddresstype       = "IPV4"
  }
}

#####
# ADC Authentication LDAP Action variables
#####
variable "adc-gw-authenticationldapaction" {
  type = map
  description = "[Required] ADC Authentication LDAP Action variables"
  default = {
    type = [
      "ldap"
    ]
    servername = [
      "9.9.9.9"
    ]
    ldapBase = [
      "DC=dt,DC=YourEnvironment" 
    ]
    ldapBindDn = [
      "svc_ldap@domain.local"
    ]
    ldapBindDnPassword = [
      "NewSecurePassword"
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
      "PLAINTEXT"
    ]
    passwdChange = [
      "DISABLED"
    ]
  }
}

#####
# ADC Authentication LDAP Policy variables
#####
variable "adc-gw-authenticationldappolicy" {
  type = map
  description = "[Required] ADC Authentication LDAP Policy variables"
  default = {
    rule = [
      "ns_true"
    ]
    reqaction = [
      "auth_act_ldap_domain.local"
    ]
  }
}

#####
# ADC CS variables
#####
variable "adc-cs" {
  type = map
  description = "[Required] ADC CS variables]"
  default = {
    vserver_name        = "cs_vs_any.domain.local_ssl_443"
    vserver_ip          = "192.168.1.12"
    vserver_port        = 443
    vserver_type        = "SSL"
  }
}

variable "adc-cs-gw" {
  type = map
  default = {
    name = [
      "citrix"
    ]
  }
}

variable "adc-cs-lb" {
  type = map
  default = {
    name = [
    ]
  }
}

variable adc-finish {
  type = map
  description = ""
  default = {
    dnsvservername  = "lb_vs_dc.domain.local_DNS_53"
    dnsvservertype  = ""
  }
}