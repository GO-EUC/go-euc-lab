
# Add servers (service object)
resource "citrixadc_server" "lb_server" {
  # Loop through each server object
  for_each = var.servers
  name = each.value.hostname
  ipaddress = each.value.ip_address

}

# Add Service Groups
resource "citrixadc_servicegroup" "lb_servicegroup" {
  # Loop through each service group object
  for_each = var.service_groups
  servicegroupname  = each.value.name
  servicetype       = each.value.type
  servicegroupmembers_by_servername = each.value.servers_to_bind
  lbvservers = each.value.virtual_server_bindings

  depends_on = [citrixadc_server.lb_server, citrixadc_lbvserver.lb_vserver]
}


# Add and configure LB vServer
resource "citrixadc_lbvserver" "lb_vserver" {
  
  for_each = var.virtual_servers

  name            = each.value.name
  servicetype     = each.value.servicetype
  ipv46           = each.value.ipv46
  port            = each.value.port
  lbmethod        = each.value.lbmethod
  persistencetype = each.value.persistencetype
  timeout         = each.value.timeout
  sslprofile      = each.value.sslprofile
  httpprofilename = each.value.httpprofilename
  tcpprofilename  = each.value.tcpprofilename

  depends_on = [
    citrixadc_nstcpprofile.base_tcp_prof,
    citrixadc_nshttpprofile.base_http_prof,
    citrixadc_sslcipher.ssl_cg_fe_TLS1213,
    citrixadc_sslcipher.ssl_cg_fe_TLS13,
    citrixadc_sslprofile.ssl_prof_fe_13,
    citrixadc_sslprofile.ssl_prof_fe_13_SNI,
  ]  
}


