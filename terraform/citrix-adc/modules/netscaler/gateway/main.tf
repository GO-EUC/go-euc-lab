#####
# Enable Citrix Gateway Feature
#####
resource "citrixadc_nsfeature" "gw_nsfeature" {
  sslvpn = true
}

#####
# Add Citrix GW vServer
#####
resource "citrixadc_vpnvserver" "gw_vserver" {
  name            = "gw_vs_${var.adc-gw.name}.${var.adc-gw.fqdn_ext}_${var.adc-gw.servicetype}_443"
  servicetype     = var.adc-gw.servicetype
  ipv46           = var.adc-gw.ip
  port            = var.adc-gw.port
  dtls            = var.adc-gw.dtls
  tcpprofilename  = "tcp_prof_${var.adc-base.environmentname}"
  httpprofilename = "http_prof_${var.adc-base.environmentname}"
  appflowlog      = var.adc-gw.appflowlog
}

#####
# Bind SSL profile to GW vServer
#####
resource "citrixadc_sslvserver" "gw_vserver_sslprofile" {
  vservername = citrixadc_vpnvserver.gw_vserver.name
  sslprofile  = "ssl_prof_${var.adc-base.environmentname}_fe_TLS1213"

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}

#####
# Bind STA Servers to GW vServer
#####
resource "citrixadc_vpnvserver_staserver_binding" "gw_vserver_staserver_binding" {
  name           = citrixadc_vpnvserver.gw_vserver.name
  staserver      = "http://${var.adc-gw.staserver}.${var.adc-gw.fqdn_int}"
  staaddresstype = var.adc-gw.staaddresstype

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}

#####
# Add Session Action Receiver
#####
resource "citrixadc_vpnsessionaction" "gw_sess_act_receiver" {
  name = "sess_prof_sf_receiver"
  clientlessmodeurlencoding = "TRANSPARENT"
  clientlessvpnmode = "ON"
  defaultauthorizationaction = "ALLOW"
  dnsvservername = var.adc-gw.dnsvservername
  icaproxy = "OFF"
  sesstimeout = "2880"
  sso = "ON"
  ssocredential = "PRIMARY"
  storefronturl = "${var.adc-gw.citrix-backend}"
  transparentinterception = "OFF"
  wihome = "${var.adc-gw.citrix-backend}"
  windowsautologon = "ON"

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}

#####
# Add Session Action Receiver Web
#####
resource "citrixadc_vpnsessionaction" "gw_sess_act_receiver_web" {
  name = "sess_prof_sf_receiver_web"
  clientchoices = "OFF"
  clientlessmodeurlencoding = "TRANSPARENT"
  clientlessvpnmode = "OFF"
  defaultauthorizationaction = "ALLOW"
  dnsvservername = var.adc-gw.dnsvservername
  icaproxy = "ON"
  locallanaccess = "ON"
  rfc1918 = "OFF"
  sesstimeout = "2880"
  sso = "ON"
  ssocredential = "PRIMARY"
  wihome = "${var.adc-gw.citrix-backend}"
  windowsautologon = "ON"
  wiportalmode = "NORMAL"

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}

#####
# Add Session Policies
#####
resource "citrixadc_vpnsessionpolicy" "gw_sess_pol_receiver" {
  name = "sess_pol_sf_receiver"
  rule = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\") && HTTP.REQ.HEADER(\"X-Citrix-Gateway\").EXISTS"
  action = "sess_prof_sf_receiver"

  depends_on = [
    citrixadc_vpnsessionaction.gw_sess_act_receiver
  ]
}

resource "citrixadc_vpnsessionpolicy" "gw_sess_pol_receiver_web" {
  name = "sess_pol_sf_receiver_web"
  rule = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\").NOT" 
  action = "sess_prof_sf_receiver_web"

  depends_on = [
    citrixadc_vpnsessionaction.gw_sess_act_receiver_web
  ]
}

#####s
# Bind session policies to GW vServer
#####
resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "gw_vserver_vpnsessionpolicy_binding_receiver" {
  name      = citrixadc_vpnvserver.gw_vserver.name
  policy    = citrixadc_vpnsessionpolicy.gw_sess_pol_receiver.name
  priority  = 100

  depends_on = [
    citrixadc_vpnsessionpolicy.gw_sess_pol_receiver
  ]
}

resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "gw_vserver_vpnsessionpolicy_binding_receiver_web" {
  name      = citrixadc_vpnvserver.gw_vserver.name
  policy    = citrixadc_vpnsessionpolicy.gw_sess_pol_receiver_web.name
  priority  = 110

  depends_on = [
    citrixadc_vpnsessionpolicy.gw_sess_pol_receiver_web
  ]
}

resource "citrixadc_authenticationldapaction" "gw_authenticationldapaction" {
  count              = length(var.adc-gw-authenticationldapaction.type)  
  name               = "auth_act_${element(var.adc-gw-authenticationldapaction["type"],count.index)}_${var.adc-gw.fqdn_int}"
  servername         = element(var.adc-gw-authenticationldapaction["servername"],count.index)
  ldapbase           = element(var.adc-gw-authenticationldapaction["ldapBase"],count.index)
  ldapbinddn         = element(var.adc-gw-authenticationldapaction["ldapBindDn"],count.index)
  ldapbinddnpassword = element(var.adc-gw-authenticationldapaction["ldapBindDnPassword"],count.index)
  ldaploginname      = element(var.adc-gw-authenticationldapaction["ldapLoginName"],count.index)
  groupattrname      = element(var.adc-gw-authenticationldapaction["groupAttrName"],count.index)
  subattributename   = element(var.adc-gw-authenticationldapaction["subAttributeName"],count.index)
  ssonameattribute   = element(var.adc-gw-authenticationldapaction["ssoNameAttribute"],count.index)
  sectype            = element(var.adc-gw-authenticationldapaction["secType"],count.index)
  passwdchange       = element(var.adc-gw-authenticationldapaction["passwdChange"],count.index)

    depends_on = [
      citrixadc_vpnvserver.gw_vserver
    ]
}

#####
# Bind authentication profile to policy
#####

resource "citrixadc_authenticationldappolicy" "gw_authenticationldappolicy" {
    count     = length(var.adc-gw-authenticationldapaction.type)
    name      = "auth_pol_${element(var.adc-gw-authenticationldapaction["type"],count.index)}_${var.adc-gw.fqdn_int}"
    rule      = element(var.adc-gw-authenticationldappolicy["rule"],count.index)
    reqaction = element(var.adc-gw-authenticationldappolicy["reqaction"],count.index)

    depends_on = [
        citrixadc_authenticationldapaction.gw_authenticationldapaction
    ]
}

#####
# Bind authentication policies to GW vServer
#####

resource "citrixadc_vpnvserver_authenticationldappolicy_binding" "gw_vserver_authenticationldappolicy_binding" {
    name        = citrixadc_vpnvserver.gw_vserver.name
    policy      = var.adc-gw.authenticationpolicy
    priority    = 100
    bindpoint   = "REQUEST"
    
    depends_on = [
        citrixadc_authenticationldappolicy.gw_authenticationldappolicy
    ]
}

#####
# Bind SSL certificate to SSL GW vServers
#####

resource "citrixadc_sslvserver_sslcertkey_binding" "gw_sslvserver_sslcertkey_binding" {
  vservername = citrixadc_vpnvserver.gw_vserver.name
  certkeyname = "ssl_cert_${var.adc-base.environmentname}_Server"
  snicert     = false

  depends_on = [
    citrixadc_vpnvserver_authenticationldappolicy_binding.gw_vserver_authenticationldappolicy_binding
  ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "gw_save" {    
  all        = true
  timestamp  = timestamp()

  depends_on = [
    citrixadc_sslvserver_sslcertkey_binding.gw_sslvserver_sslcertkey_binding
  ]
}