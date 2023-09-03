#####
# Define Locals
#####
locals {
  lb-srv-name           = "lb_srv_letsencrypt_backend"
  lb-sg-name            = "lb_sg_letsencrypt_backend"
  lb-sg-healthmonitor   = "NO"
  lb-vs-name            = "lb_vs_letsencrypt"  
  lb-vs-lbmethod        = "LEASTCONNECTION"
  lb-vs-persistencetype = "SOURCEIP"
  lb-vs-timeout         = "2"
}

#####
# Add LB Server
#####
resource "citrixadc_server" "le_lb_install_server" {
  name      = local.lb-srv-name
  ipaddress = var.adc-letsencrypt-lb.backend-ip
}

#####
# Add LB Service Groups
#####
resource "citrixadc_servicegroup" "le_lb_install_servicegroup" {

  servicegroupname  = local.lb-sg-name
  servicetype       = var.adc-letsencrypt-lb.servicetype
  healthmonitor     = local.lb-sg-healthmonitor

  depends_on = [
    citrixadc_server.le_lb_install_server
  ]
}

#####
# Bind LB Server to Service Groups
#####
resource "citrixadc_servicegroup_servicegroupmember_binding" "le_lb_install_sg_server_binding" {
  servicegroupname  = citrixadc_servicegroup.le_lb_install_servicegroup.servicegroupname
  servername        = citrixadc_server.le_lb_install_server.name
  port              = var.adc-letsencrypt-lb.port

  depends_on = [
    citrixadc_servicegroup.le_lb_install_servicegroup
  ]
}

#####
# Add and configure LB vServer - Type http
#####
resource "citrixadc_lbvserver" "le_lb_install_vserver_http" {
  name            = local.lb-vs-name
  servicetype     = var.adc-letsencrypt-lb.servicetype
  ipv46           = var.adc-letsencrypt-lb.frontend-ip
  port            = var.adc-letsencrypt-lb.port
  lbmethod        = local.lb-vs-lbmethod
  persistencetype = local.lb-vs-persistencetype
  timeout         = local.lb-vs-timeout

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.le_lb_install_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####
resource "citrixadc_lbvserver_servicegroup_binding" "le_lb_install_vserver_sg_binding" {
  name              = citrixadc_lbvserver.le_lb_install_vserver_http.name
  servicegroupname  = citrixadc_servicegroup.le_lb_install_servicegroup.servicegroupname

  depends_on = [
    citrixadc_lbvserver.le_lb_install_vserver_http
  ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "le_lb_install_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
    citrixadc_lbvserver_servicegroup_binding.le_lb_install_vserver_sg_binding
  ]
}

#####
# Wait a few seconds
#####
resource "time_sleep" "le_lb_wait_a_few_seconds" {
  create_duration = "15s"

  depends_on = [
    citrixadc_nsconfig_save.le_lb_install_save
  ]
}