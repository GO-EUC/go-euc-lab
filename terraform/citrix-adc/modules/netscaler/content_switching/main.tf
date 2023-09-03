#####
# Define Locals
#####
locals {
  vserver_sslprofile = "ssl_prof_${var.adc-base.environmentname}_fe_TLS1213"
  vserver_httpprofile = "http_prof_${var.adc-base.environmentname}"
  vserver_tcpprofile  = "tcp_prof_${var.adc-base.environmentname}" 
}

#####
# Add Content Switching Actions
#####
resource "citrixadc_csaction" "cs_action_lb" {
  count           = length(var.adc-cs-lb.name)
  name            = "cs_act_${element(var.adc-cs-lb["name"],count.index)}.${var.adc-base.fqdn_int}_http_80"
  targetlbvserver = "lb_vs_${element(var.adc-cs-lb["name"],count.index)}.${var.adc-base.fqdn_int}_http_80"
}

resource "citrixadc_csaction" "cs_action_gw" {
  count         = length(var.adc-cs-gw.name)
  name          = "cs_act_${element(var.adc-cs-gw["name"],count.index)}.${var.adc-base.fqdn_ext}_ssl_443"
  targetvserver = "gw_vs_${element(var.adc-cs-gw["name"],count.index)}.${var.adc-base.fqdn_ext}_ssl_443"
}

#####
# Add Content Switching Policies
#####
resource "citrixadc_cspolicy" "cs_policy_lb" {
  count      = length(var.adc-cs-lb.name)
  policyname = "cs_pol_${element(var.adc-cs-lb["name"],count.index)}.${var.adc-base.fqdn_ext}_http_80"
  rule       = "HTTP.REQ.HOSTNAME.CONTAINS(\"${element(var.adc-cs-lb["name"],count.index)}.${var.adc-base.fqdn_ext}\")"
  action     = "cs_act_${element(var.adc-cs-lb["name"],count.index)}.${var.adc-base.fqdn_int}_http_80"

  depends_on = [
    citrixadc_csaction.cs_action_lb,
    citrixadc_csaction.cs_action_gw
  ]
}

resource "citrixadc_cspolicy" "cs_policy_gw" {
  count      = length(var.adc-cs-gw.name)
  policyname = "cs_pol_${element(var.adc-cs-gw["name"],count.index)}.${var.adc-base.fqdn_ext}_ssl_443"
  rule       = "HTTP.REQ.HOSTNAME.CONTAINS(\"${element(var.adc-cs-gw["name"],count.index)}.${var.adc-base.fqdn_ext}\")"
  action     = "cs_act_${element(var.adc-cs-gw["name"],count.index)}.${var.adc-base.fqdn_ext}_ssl_443"

  depends_on = [
    citrixadc_csaction.cs_action_lb,
    citrixadc_csaction.cs_action_gw
  ]
}

#####
# Add Content Switching vServer
#####
resource "citrixadc_csvserver" "cs_vserver" {
  name            = "cs_vs_${var.adc-cs.vserver_name}.${var.adc-base.fqdn_ext}_${var.adc-cs.vserver_type}_${var.adc-cs.vserver_port}"
  ipv46           = var.adc-cs.vserver_ip
  port            = var.adc-cs.vserver_port
  servicetype     = var.adc-cs.vserver_type
  sslprofile      = local.vserver_sslprofile
  httpprofilename = local.vserver_httpprofile
  tcpprofilename  = local.vserver_tcpprofile

  depends_on = [
    citrixadc_cspolicy.cs_policy_lb,
    citrixadc_cspolicy.cs_policy_gw
  ]
}

#####
# Bind Content Switching Policies to Content Switching vServer
#####
resource "citrixadc_csvserver_cspolicy_binding" "cs_vserverpolicybinding_lb" {
    count                  = length(var.adc-cs-lb.name)
    name                   = citrixadc_csvserver.cs_vserver.name
    policyname             = citrixadc_cspolicy.cs_policy_lb[count.index].policyname
    priority               = (count.index + 1 )* 10
    gotopriorityexpression = "END"
 
  depends_on  = [
    citrixadc_csvserver.cs_vserver
  ]
}

resource "citrixadc_csvserver_cspolicy_binding" "cs_vserverpolicybinding_gw" {
    count                  = length(var.adc-cs-gw.name)
    name                   = citrixadc_csvserver.cs_vserver.name
    policyname             = citrixadc_cspolicy.cs_policy_gw[count.index].policyname
    priority               = (count.index + 1) * 1000
    gotopriorityexpression = "END"

  depends_on  = [
    citrixadc_csvserver.cs_vserver
  ]
}

#####
# Bind SSL certificate to CS vServers
#####
resource "citrixadc_sslvserver_sslcertkey_binding" "cs_sslvserver_sslcertkey_binding" {
    vservername = citrixadc_csvserver.cs_vserver.name
    certkeyname = "ssl_cert_${var.adc-base.environmentname}_Server"
    snicert     = false

    depends_on  = [
      citrixadc_csvserver.cs_vserver
    ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "cs_save" {    
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_csvserver_cspolicy_binding.cs_vserverpolicybinding_gw,
        citrixadc_csvserver_cspolicy_binding.cs_vserverpolicybinding_lb,
        citrixadc_sslvserver_sslcertkey_binding.cs_sslvserver_sslcertkey_binding
    ]
}