#####
# ADC Loadbalancing Server
#####

resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb-server.name)
  name      = element(var.adc-lb-server["name"],count.index)
  ipaddress = element(var.adc-lb-server["ip"],count.index)
}

#####
# ADC Loadbalancing Servicegroups
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
# ADC Loadbalancing Servicegroup-Server-Bindings
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
# ADC Loadbalancing vServer - Type SSL
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
# ADC Loadbalancing vServer - Type DNS
#####

resource "citrixadc_lbvserver" "lb_vserver_dns" {
  count   = length(var.adc-lb-vserver-dns.name)
  name    = element(var.adc-lb-vserver-dns["name"],count.index)

  servicetype = element(var.adc-lb-vserver-dns["servicetype"],count.index)
  ipv46 = element(var.adc-lb-vserver-dns["ipv46"],count.index)
  port = element(var.adc-lb-vserver-dns["port"],count.index)
  lbmethod = element(var.adc-lb-vserver-dns["lbmethod"],count.index)
  persistencetype = element(var.adc-lb-vserver-dns["persistencetype"],count.index)
  timeout = element(var.adc-lb-vserver-dns["timeout"],count.index)

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# ADC Loadbalancing vServer-Servicegroup-Bindings
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
# Save config
#####

resource "citrixadc_nsconfig_save" "tf_ns_save" {  
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
    ]
}