locals {
  httpprofilename = "http_prof_${var.adc-base.environmentname}"
  tcpprofilename  = "tcp_prof_${var.adc-base.environmentname}"
  sslprofilename  = "ssl_prof_${var.adc-base.environmentname}_fe_TLS1213"
}

#####
# Add LB Server
#####
resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb-srv.name)
  name      = "lb_srv_${element(var.adc-lb-srv["name"],count.index)}"
  ipaddress = element(var.adc-lb-srv["ip"],count.index)
}

#####
# Add LB Service Groups
#####
resource "citrixadc_servicegroup" "lb_servicegroup" {
  count             = length(var.adc-lb.name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}.${var.adc-lb.fqdn_int}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servicetype       = element(var.adc-lb["type"],count.index)

  depends_on = [
    citrixadc_server.lb_server
  ]
}

#####
# Bind LB Server to Service Groups
#####
resource "citrixadc_servicegroup_servicegroupmember_binding" "lb_sg_server_binding" {
  count             = length(var.adc-lb.name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}.${var.adc-lb.fqdn_int}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servername        = "lb_srv_${element(var.adc-lb["backend-server"],count.index)}"
  port              = element(var.adc-lb["port"],count.index)

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup
  ]
}

#####
# Add and configure LB vServer
#####
resource "citrixadc_lbvserver" "lb_vserver" {
  count           = length(var.adc-lb.name)
  name            = "lb_vs_${element(var.adc-lb["name"],count.index)}.${var.adc-lb.fqdn_int}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"

  servicetype     = element(var.adc-lb["type"],count.index)
  ipv46           = element(var.adc-lb["lb-type"],count.index) == "direct" ? "9.9.9.9" : "0.0.0.0"
  port            = element(var.adc-lb["lb-type"],count.index) == "direct" ? element(var.adc-lb["port"],count.index) : "0"
  lbmethod        = var.adc-lb-generic.lbmethod
  persistencetype = var.adc-lb-generic.persistencetype
  timeout         = var.adc-lb-generic.timeout
  sslprofile      = element(var.adc-lb["type"],count.index) == "SSL" ? local.sslprofilename : null
  httpprofilename = element(var.adc-lb["type"],count.index) == "DNS" || element(var.adc-lb["type"],count.index) == "TCP" ? null : local.httpprofilename
  tcpprofilename  = element(var.adc-lb["type"],count.index) == "DNS" ? null : local.tcpprofilename

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####
resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding" {
  count             = length(var.adc-lb.name)
  name              = "lb_vs_${element(var.adc-lb["name"],count.index)}.${var.adc-lb.fqdn_int}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}.${var.adc-lb.fqdn_int}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"

  depends_on = [
    citrixadc_lbvserver.lb_vserver
  ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}