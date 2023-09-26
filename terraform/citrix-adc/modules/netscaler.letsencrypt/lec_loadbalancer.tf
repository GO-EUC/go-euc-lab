# Add LB Server
resource "citrixadc_server" "le_lb_install_server" {
  name      = var.letsencrypt_lb.lb_srv_name
  ipaddress = var.letsencrypt_lb.backend_ip
}

# Add LB Service Groups
resource "citrixadc_servicegroup" "le_lb_install_servicegroup" {

  servicegroupname = var.letsencrypt_lb.lb_sg_name
  servicetype      = var.letsencrypt_lb.servicetype
  healthmonitor    = var.letsencrypt_lb.lb_sg_healthmonitor

  depends_on = [
    citrixadc_server.le_lb_install_server
  ]
}

# Bind LB Server to Service Groups
resource "citrixadc_servicegroup_servicegroupmember_binding" "le_lb_install_sg_server_binding" {
  servicegroupname = citrixadc_servicegroup.le_lb_install_servicegroup.servicegroupname
  servername       = citrixadc_server.le_lb_install_server.name
  port             = var.letsencrypt_lb.port

  depends_on = [
    citrixadc_servicegroup.le_lb_install_servicegroup
  ]
}

#####
# Add and configure LB vServer _ Type http
#####
resource "citrixadc_lbvserver" "le_lb_install_vserver_http" {
  name            = var.letsencrypt_lb.lb_vs_name
  servicetype     = var.letsencrypt_lb.servicetype
  ipv46           = var.letsencrypt_lb.frontend_ip
  port            = var.letsencrypt_lb.port
  lbmethod        = var.letsencrypt_lb.lb_vs_lbmethod
  persistencetype = var.letsencrypt_lb.lb_vs_persistencetype
  timeout         = var.letsencrypt_lb.lb_vs_timeout

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.le_lb_install_sg_server_binding
  ]
}

# Bind LB Service Groups to LB vServers
resource "citrixadc_lbvserver_servicegroup_binding" "le_lb_install_vserver_sg_binding" {
  name             = citrixadc_lbvserver.le_lb_install_vserver_http.name
  servicegroupname = citrixadc_servicegroup.le_lb_install_servicegroup.servicegroupname

  depends_on = [
    citrixadc_lbvserver.le_lb_install_vserver_http
  ]
}

# Save config
resource "citrixadc_nsconfig_save" "le_lb_install_save" {
  all       = true
  timestamp = timestamp()

  depends_on = [
    citrixadc_lbvserver_servicegroup_binding.le_lb_install_vserver_sg_binding
  ]
}

