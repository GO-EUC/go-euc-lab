# ToDo: Eliminate requirement to sudo for starting the http service

#####
# Add LB Server
#####

resource "citrixadc_server" "lb_server_letsencrypt" {
  name      = "lb_srv_YourServerName"
  ipaddress = "10.10.1.20"
}

#####
# Add LB Service Groups
#####

resource "citrixadc_servicegroup" "lb_servicegroup_letsencrypt" {

  servicegroupname  = "lb_sg_YourServerName_http_80"
  servicetype       = "http"
  healthmonitor     = "NO"

  depends_on = [
    citrixadc_server.lb_server_letsencrypt
  ]
}

#####
# Bind LB Server to Service Groups
#####

resource "citrixadc_servicegroup_servicegroupmember_binding" "lb_sg_server_binding_letsencrypt" {
  servicegroupname  = "lb_sg_YourServerName_http_80"
  servername        = "lb_srv_YourServerName"
  port              = "80"

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup_letsencrypt
  ]
}

#####
# Add and configure LB vServer - Type SSL
#####

resource "citrixadc_lbvserver" "lb_vserver_letsencrypt" {
  name    = "lb_vs_YourServerName_http_80"
  servicetype = "http"
  ipv46 = "10.10.1.17"
  port = 80

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding_letsencrypt
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####

resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding_letsencrypt" {
  name              = "lb_vs_YourServerName_http_80"
  servicegroupname  = "lb_sg_YourServerName_http_80"

  depends_on = [
    citrixadc_lbvserver.lb_vserver_letsencrypt
  ]
}


#####
# Save config
#####

resource "citrixadc_nsconfig_save" "ns_save_letsencrypt_lb" {  
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding_letsencrypt
    ]
}