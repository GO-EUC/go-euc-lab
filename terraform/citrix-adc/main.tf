# # Module terraform-module-citrix-adc-build
# module "adc-01-build" {
#   source = "modules/vsphere_deploy"

#   vsphere = {
#     server       = var.vsphere.server
#     user         = var.vsphere.user
#     password     = var.vsphere.password
#     datacenter   = var.vsphere.datacenter
#     host         = var.vsphere.host
#     datastore    = var.vsphere.datastore
#     timezone     = var.vsphere.timezone
#     resourcepool = var.vsphere.resourcepool
#   }

#   vm = {
#     network = var.vm.network
#     mac     = var.vm.mac
#     ip      = var.vm.ip
#     gateway = var.vm.gateway
#     netmask = var.vm.netmask
#     name    = var.vm.name
#     ovf     = var.vm.ovf
#   }  
# }

module "netscaler" {
  source = "./modules/netscaler/"

  vm = {
    ip = var.vm.ip
  }  
  adc-base = {
    username    = var.adc-base.username
    password    = var.adc-base.password
    oldpassword = var.adc-base.oldpassword
  }
}

# module "adc-03-license" {
#   source = "modules/netscaler/netscaler_license"

#   vm = {
#     ip = var.vm.ip
#   }  
#   adc-base = {
#     username    = var.adc-base.username
#     password    = var.adc-base.password
#   }

#   adc-license = {
#     filename     = var.adc-license.filename 
#     filecontent  = file(var.adc-license.filecontent)
#   }
  
# }

module "adc-04-base" {
  source = "./modules/netscaler/base_configuration"
  
  vm = {
    ip       = var.vm.ip
    hostname = var.vm.name
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
    timezone        = var.adc-base.timezone
  }

  adc-snip = {
    ip      = var.adc-snip.ip
    netmask = var.adc-snip.netmask
    icmp    = var.adc-snip.icmp
  }
}

module "adc-05-ssl" {
    source = "./modules/netscaler/ssl_configuration"
  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
    fqdn_ext        = var.adc-base.fqdn_ext
  }
}

module "adc-06-letsencrypt-lb" {
    source = "./modules/netscaler/letsencrypt_lb"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
  }

  adc-letsencrypt-lb = {
    backend-ip  = var.adc-letsencrypt-lb.backend-ip
    frontend-ip = var.adc-letsencrypt-lb.frontend-ip
    servicetype = var.adc-letsencrypt-lb.servicetype 
    port        = var.adc-letsencrypt-lb.port
  }

}

module "adc-07-letsencrypt" {
    source = "./modules/netscaler/letsencrypt"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
    fqdn_ext        = var.adc-base.fqdn_ext
  }

  adc-letsencrypt-certificate = {
    private_key_algorithm      = var.adc-letsencrypt-certificate.private_key_algorithm
    private_key_rsa_bits       = var.adc-letsencrypt-certificate.private_key_rsa_bits
    private_key_ecdsa_curve    = var.adc-letsencrypt-certificate.private_key_ecdsa_curve
    registration_email_address = var.adc-letsencrypt-certificate.registration_email_address
    common_name                = var.adc-letsencrypt-certificate.common_name
  }

  adc-letsencrypt-certificate-san = var.adc-letsencrypt-certificate-san

}

module "adc-09-lb" {
  source = "./modules/netscaler/loadbalancers"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
  }

  adc-lb = {
    name           = var.adc-lb.name
    type           = var.adc-lb.type
    port           = var.adc-lb.port
    lb-type        = var.adc-lb.lb-type
    backend-server = var.adc-lb.backend-server
    fqdn_int       = var.adc-base.fqdn_int
  }
  adc-lb-srv = {
    name = var.adc-lb-srv.name
    ip   = var.adc-lb-srv.ip
  }

  adc-lb-generic = {
    lbmethod         = var.adc-lb-generic.lbmethod
    persistencetype  = var.adc-lb-generic.persistencetype
    timeout          = var.adc-lb-generic.timeout
    sslsnicert       = var.adc-lb-generic.sslsnicert
  }
}

module "adc-10-gateway" {
    source = "./modules/netscaler/gateway"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
  }
  adc-gw = {
    name                 = var.adc-gw.name
    fqdn_ext             = var.adc-base.fqdn_ext
    fqdn_int             = var.adc-base.fqdn_int
    staserver            = var.adc-gw.staserver
    dnsvservername       = var.adc-gw.dnsvservername
    authenticationpolicy = var.adc-gw.authenticationpolicy
    citrix-backend       = var.adc-gw.citrix-backend 
    servicetype          = var.adc-gw.servicetype
    ip                   = var.adc-gw.ip
    port                 = var.adc-gw.port
    dtls                 = var.adc-gw.dtls
    appflowlog           = var.adc-gw.appflowlog
    staaddresstype       = var.adc-gw.staaddresstype
  }

  adc-gw-authenticationldapaction = {
    type               = var.adc-gw-authenticationldapaction.type
    servername         = var.adc-gw-authenticationldapaction.servername
    ldapBase           = var.adc-gw-authenticationldapaction.ldapBase
    ldapBindDn         = var.adc-gw-authenticationldapaction.ldapBindDn
    ldapBindDnPassword = var.adc-gw-authenticationldapaction.ldapBindDnPassword
    ldapLoginName      = var.adc-gw-authenticationldapaction.ldapLoginName
    groupAttrName      = var.adc-gw-authenticationldapaction.groupAttrName
    subAttributeName   = var.adc-gw-authenticationldapaction.subAttributeName
    ssoNameAttribute   = var.adc-gw-authenticationldapaction.ssoNameAttribute
    secType            = var.adc-gw-authenticationldapaction.secType
    passwdChange       = var.adc-gw-authenticationldapaction.passwdChange
  }

  adc-gw-authenticationldappolicy = {
    rule      = var.adc-gw-authenticationldappolicy.rule
    reqaction = var.adc-gw-authenticationldappolicy.reqaction
  }
}

module "adc-11-cs" {
    source = "./modules/netscaler/content_switching"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
    fqdn_int        = var.adc-base.fqdn_int
    fqdn_ext        = var.adc-base.fqdn_ext
  }

  adc-cs = {
    vserver_name        = var.adc-cs.vserver_name 
    vserver_ip          = var.adc-cs.vserver_ip 
    vserver_port        = var.adc-cs.vserver_port
    vserver_type        = var.adc-cs.vserver_type
  }

  adc-cs-lb = {
    name = var.adc-cs-lb.name
  }

  adc-cs-gw = {
    name = var.adc-cs-gw.name
  }
}

module "adc-99-finish" {
    source = "./modules/netscaler/final_operations"

  vm = {
    ip = var.vm.ip
  }

  adc-base = {
    username        = var.adc-base.username
    password        = var.adc-base.password
    environmentname = var.adc-base.environmentname
  }

  adc-finish = {
    dnsvservername  = var.adc-finish.dnsvservername
    dnsvservertype  = var.adc-finish.dnsvservertype
  }
}