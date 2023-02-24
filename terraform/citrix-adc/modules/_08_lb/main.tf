#####
# Add LB Server
#####

resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb-server.name)
  name      = element(var.adc-lb-server["name"],count.index)
  ipaddress = element(var.adc-lb-server["ip"],count.index)
}

#####
# Add LB Service Groups
#####

resource "citrixadc_servicegroup" "lb_servicegroup" {
  count             = length(var.adc-lb-servicegroup.servicegroupname)
  servicegroupname  = element(var.adc-lb-servicegroup["servicegroupname"],count.index)
  servicetype       = element(var.adc-lb-servicegroup["servicetype"],count.index)

  depends_on = [
    citrixadc_server.lb_server
  ]
}

#####
# Bind LB Server to Service Groups
#####

resource "citrixadc_servicegroup_servicegroupmember_binding" "lb_sg_server_binding" {
  count             = length(var.adc-lb-sg-server-binding.servicegroupname)
  servicegroupname  = element(var.adc-lb-sg-server-binding["servicegroupname"],count.index)
  servername        = element(var.adc-lb-sg-server-binding["servername"],count.index)
  port              = element(var.adc-lb-sg-server-binding["port"],count.index)

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup
  ]
}

#####
# Add and configure LB vServer - Type SSL
#####

resource "citrixadc_lbvserver" "lb_vserver_ssl" {
  count   = length(var.adc-lb-vserver-ssl.name)
  name    = element(var.adc-lb-vserver-ssl["name"],count.index)

  servicetype = element(var.adc-lb-vserver-ssl["servicetype"],count.index)
  sslprofile = element(var.adc-lb-vserver-ssl["sslprofile"],count.index)
  ipv46 = element(var.adc-lb-vserver-ssl["ipv46"],count.index)
  port = element(var.adc-lb-vserver-ssl["port"],count.index)
  lbmethod = element(var.adc-lb-vserver-ssl["lbmethod"],count.index)
  persistencetype = element(var.adc-lb-vserver-ssl["persistencetype"],count.index)
  timeout = element(var.adc-lb-vserver-ssl["timeout"],count.index)

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Add and configure LB vServer - Type not SSL
#####

resource "citrixadc_lbvserver" "lb_vserver_dns" {
  count   = length(var.adc-lb-vserver-notssl.name)
  name    = element(var.adc-lb-vserver-notssl["name"],count.index)

  servicetype = element(var.adc-lb-vserver-notssl["servicetype"],count.index)
  ipv46 = element(var.adc-lb-vserver-notssl["ipv46"],count.index)
  port = element(var.adc-lb-vserver-notssl["port"],count.index)
  lbmethod = element(var.adc-lb-vserver-notssl["lbmethod"],count.index)
  persistencetype = element(var.adc-lb-vserver-notssl["persistencetype"],count.index)
  timeout = element(var.adc-lb-vserver-notssl["timeout"],count.index)

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####

resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding" {
  count             = length(var.adc-lb-vserver-sg-binding.name)
  name              = element(var.adc-lb-vserver-sg-binding["name"],count.index)
  servicegroupname  = element(var.adc-lb-vserver-sg-binding["servicegroupname"],count.index)

  depends_on = [
    citrixadc_lbvserver.lb_vserver_ssl,
    citrixadc_lbvserver.lb_vserver_dns
  ]
}

#####
# Bind SSL certificate to SSL LB vServers
#####

resource "citrixadc_sslvserver_sslcertkey_binding" "sslvserver_sslcertkey_binding_lb" {
  count       = length(var.adc-lb-vserver-ssl.name)
  vservername = element(var.adc-lb-vserver-ssl["name"],count.index)
  certkeyname = "ssl_cert_democloud"
  snicert     = true

  depends_on = [
    citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "ns_save_lb" {
    
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_sslvserver_sslcertkey_binding.sslvserver_sslcertkey_binding_lb
    ]

}