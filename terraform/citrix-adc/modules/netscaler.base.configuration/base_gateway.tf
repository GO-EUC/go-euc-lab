# Create AAA vserver
resource "citrixadc_authenticationvserver" "aaa_vserver" {
    count = var.base_configuration.advanced ? 1 : 0
    name        = "AAA_LDAPS"
    servicetype = "SSL"
    authentication = "ON"
    state          = "ENABLED"
    depends_on = [citrixadc_nsfeature.advanced_nsfeature]
}

resource "citrixadc_authenticationvserver_authenticationpolicy_binding" "tf_bind" {
  name     = "AAA_LDAPS"
  policy   = "pol_auth_ldaps"
  priority = 30

  depends_on = [citrixadc_authenticationvserver.aaa_vserver, citrixadc_authenticationpolicy.auth_authpolicy  ]
}

# Create authentication profile
resource "citrixadc_authenticationauthnprofile" "gw_authentication_profile" {
  count = var.base_configuration.advanced ? 1 : 0
  name                = "authprof_aaa_ldaps"
  authnvsname         = citrixadc_authenticationvserver.aaa_vserver[count.index].name
   depends_on = [citrixadc_authenticationpolicy.auth_authpolicy]
}

# Create Gateway vServer
resource "citrixadc_vpnvserver" "gw_vserver" {
    count = var.base_configuration.advanced ? 1 : 0
    name            = var.gateway.name
    servicetype     = var.gateway.servicetype
    ipv46           = var.gateway.ipv46
    port            = var.gateway.port
    dtls            = var.gateway.dtls
    authnprofile = citrixadc_authenticationauthnprofile.gw_authentication_profile[count.index].name
    tcpprofilename  = "tcp_prof_${var.base_configuration.environment_prefix}"
    httpprofilename = "http_prof_${var.base_configuration.environment_prefix}"
    
    depends_on = [citrixadc_authenticationauthnprofile.gw_authentication_profile]
}


# Bind SSL profile to GW vServer
resource "citrixadc_sslvserver" "gw_vserver_sslprofile" {
    count = var.base_configuration.advanced ? 1 : 0
    vservername = var.gateway.name
    sslprofile  = "ssl_prof_${var.base_configuration.environment_prefix}_fe_TLS1213"

    depends_on = [
    citrixadc_vpnvserver.gw_vserver, 
    citrixadc_sslprofile.ssl_prof_fe_1213
    
    ]
}



# Bind STA Servers to GW vServer
resource "citrixadc_vpnvserver_staserver_binding" "gw_vserver_staserver_binding" {
    count = var.base_configuration.advanced ? 1 : 0
    name           =  var.gateway.name
    staserver      = "http://${var.gateway.sta}"
    staaddresstype = "IPV4"

    depends_on = [
    citrixadc_vpnvserver.gw_vserver
    ]
}


# Add Session Action Receiver
resource "citrixadc_vpnsessionaction" "gw_sess_act_receiver" {
  name = "vpn_act_receiver_advanced"
  clientlessmodeurlencoding = "TRANSPARENT"
  clientlessvpnmode = "ON"
  defaultauthorizationaction = "ALLOW"
  icaproxy = "OFF"
  sesstimeout = "2880"
  sso = "ON"
  ssocredential = "PRIMARY"
  storefronturl = var.gateway.storefronturl
  transparentinterception = "OFF"
  wihome = var.gateway.storefronturl
  windowsautologon = "ON"

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}


# Add Session Action HTML5
resource "citrixadc_vpnsessionaction" "gw_sess_act_receiver_web" {
  name = "vpn_act_web_advanced"
  clientchoices = "OFF"
  clientlessmodeurlencoding = "TRANSPARENT"
  clientlessvpnmode = "OFF"
  defaultauthorizationaction = "ALLOW"
  icaproxy = "ON"
  locallanaccess = "ON"
  rfc1918 = "OFF"
  sesstimeout = "2880"
  sso = "ON"
  ssocredential = "PRIMARY"
  storefronturl = var.gateway.storefronturl
  windowsautologon = "ON"
  wiportalmode = "NORMAL"

  depends_on = [
    citrixadc_vpnvserver.gw_vserver
  ]
}

# Add Session Policies
resource "citrixadc_vpnsessionpolicy" "gw_sess_pol_receiver" {
  name = "vpn_prof_receiver_advanced"
  rule = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\") && HTTP.REQ.HEADER(\"X-Citrix-Gateway\").EXISTS"
  action = citrixadc_vpnsessionaction.gw_sess_act_receiver.name

  depends_on = [
    citrixadc_vpnsessionaction.gw_sess_act_receiver
  ]
}

resource "citrixadc_vpnsessionpolicy" "gw_sess_pol_receiver_web" {
  name = "vpn_prof_web_advanced"
  rule = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\").NOT" 
  action = citrixadc_vpnsessionaction.gw_sess_act_receiver_web.name
  depends_on = [
    citrixadc_vpnsessionaction.gw_sess_act_receiver_web
  ]
}


# Bind session policy to GW vServer
resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "gw_vserver_vpnsessionpolicy_binding_receiver" {
  name      = var.gateway.name
  policy    = citrixadc_vpnsessionpolicy.gw_sess_pol_receiver.name
  priority  = 100

  depends_on = [
    citrixadc_vpnsessionpolicy.gw_sess_pol_receiver,
    citrixadc_vpnvserver.gw_vserver
  ]
}

# Bind session policy to GW vServer
resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "gw_vserver_vpnsessionpolicy_binding_receiver_web" {
  name      = var.gateway.name
  policy    = citrixadc_vpnsessionpolicy.gw_sess_pol_receiver_web.name
  priority  = 110

  depends_on = [
    citrixadc_vpnsessionpolicy.gw_sess_pol_receiver_web,
    citrixadc_vpnvserver.gw_vserver
  ]
}

