#####
# Add Citrix GW vServer
#####

resource "citrixadc_vpnvserver" "vpnvserver" {
    count           = length(var.adc-gw-vserver.name)
    name            = element(var.adc-gw-vserver["name"],count.index)
    servicetype     = element(var.adc-gw-vserver["servicetype"],count.index)
    ipv46           = element(var.adc-gw-vserver["ipv46"],count.index)
    port            = element(var.adc-gw-vserver["port"],count.index)
    dtls            = element(var.adc-gw-vserver["dtls"],count.index)
    tcpprofilename  = element(var.adc-gw-vserver["tcpprofilename"],count.index)
    httpprofilename = element(var.adc-gw-vserver["httpprofilename"],count.index)
    appflowlog      = element(var.adc-gw-vserver["appflowlog"],count.index)
}

#####
# Bind SSL profile to GW vServer
#####

resource "citrixadc_sslvserver" "sslvserver_vpnvserver" {
    count       = length(var.adc-gw-vserver.name)
    vservername = citrixadc_vpnvserver.vpnvserver[count.index].name
    sslprofile  = "ssl_prof_goeuc_fe_TLS1213"
}


#####
# Bind STA Servers to GW vServer
#####

resource "citrixadc_vpnvserver_staserver_binding" "vpnvserver_staserver_binding" {
    count          = length(var.adc-gw-vserver-staserverbinding.name)
    name           = element(var.adc-gw-vserver-staserverbinding["name"],count.index)
    staserver      = element(var.adc-gw-vserver-staserverbinding["staserver"],count.index)
    staaddresstype = element(var.adc-gw-vserver-staserverbinding["staaddresstype"],count.index)

    depends_on = [
        citrixadc_vpnvserver.vpnvserver
    ]
}

#####
# Add Session Action Receiver - Static for now
#####

resource "citrixadc_vpnsessionaction" "vpnsessionaction_receiver" {
    name                        = "sess_prof_sf_receiver"
    clientlessmodeurlencoding   = "TRANSPARENT"
    clientlessvpnmode           = "ON"
    defaultauthorizationaction  = "ALLOW"
    dnsvservername              = "lb_vs_dc-goeuc-local_dns_53"
    icaproxy                    = "OFF"
    sesstimeout                 = "2880"
    sso                         = "ON"
    ssocredential               = "PRIMARY"
    storefronturl               = "https://sf.goeuc.local/"
    transparentinterception     = "OFF"
    wihome                      = "https://sf.goeuc.local/"
    windowsautologon            = "ON"

    depends_on = [
        citrixadc_vpnvserver.vpnvserver
    ]
}

#####
# Add Session Action Receiver Web
#####

resource "citrixadc_vpnsessionaction" "vpnsessionaction_receiver_web" {
    name                        = "sess_prof_sf_receiver_web"
    clientchoices               = "OFF"
    clientlessmodeurlencoding   = "TRANSPARENT"
    clientlessvpnmode           = "OFF"
    defaultauthorizationaction  = "ALLOW"
    dnsvservername              = "lb_vs_dc-goeuc-local_dns_53"
    icaproxy                    = "ON"
    locallanaccess              = "ON"
    rfc1918                     = "OFF"
    sesstimeout                 = "2880"
    sso                         = "ON"
    ssocredential               = "PRIMARY"
    wihome                      = "https://sf.goeuc.local/Citrix/StoreWeb/"
    windowsautologon            = "ON"
    wiportalmode                = "NORMAL"

    depends_on = [
        citrixadc_vpnvserver.vpnvserver
    ]
}

#####
# Add Session Policiy Receiver
#####

resource "citrixadc_vpnsessionpolicy" "vpnsessionpolicy_receiver" {
    name   = "sess_pol_sf_receiver"
    rule   = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\") && HTTP.REQ.HEADER(\"X-Citrix-Gateway\").EXISTS" 
    action = "sess_prof_sf_receiver"

    depends_on = [
        citrixadc_vpnsessionaction.vpnsessionaction_receiver
    ]
}

resource "citrixadc_vpnsessionpolicy" "vpnsessionpolicy_receiver_web" {
    name   = "sess_pol_sf_receiver_web"
    rule   = "HTTP.REQ.HEADER(\"User-Agent\").CONTAINS(\"CitrixReceiver\").NOT && HTTP.REQ.HEADER(\"Referer\").EXISTS" 
    action = "sess_prof_sf_receiver"

    depends_on = [
        citrixadc_vpnsessionaction.vpnsessionaction_receiver_web
    ]
}

#####
# Bind session policies to GW vServer
#####

resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "vpnvserver_vpnsessionpolicy_binding" {
    count     = length(var.adc-gw-vserver-vpnsessionpolicybinding.name)
    name      = element(var.adc-gw-vserver-vpnsessionpolicybinding["name"],count.index)
    policy    = element(var.adc-gw-vserver-vpnsessionpolicybinding["policy"],count.index)
    priority  = element(var.adc-gw-vserver-vpnsessionpolicybinding["priority"],count.index)

    depends_on = [
        citrixadc_vpnsessionpolicy.vpnsessionpolicy_receiver_web,
        citrixadc_vpnsessionpolicy.vpnsessionpolicy_receiver_web
    ]
}

resource "citrixadc_authenticationldapaction" "authenticationldapaction" {
    count              = length(var.adc-gw-vserver-authenticationldapaction.name)
    name               = element(var.adc-gw-vserver-authenticationldapaction["name"],count.index)
    servername         = element(var.adc-gw-vserver-authenticationldapaction["servername"],count.index)
    ldapbase           = element(var.adc-gw-vserver-authenticationldapaction["ldapBase"],count.index)
    ldapbinddn         = element(var.adc-gw-vserver-authenticationldapaction["ldapBindDn"],count.index)
    ldapbinddnpassword = element(var.adc-gw-vserver-authenticationldapaction["ldapBindDnPassword"],count.index)
    ldaploginname      = element(var.adc-gw-vserver-authenticationldapaction["ldapLoginName"],count.index)
    groupattrname      = element(var.adc-gw-vserver-authenticationldapaction["groupAttrName"],count.index)
    subattributename   = element(var.adc-gw-vserver-authenticationldapaction["subAttributeName"],count.index)
    ssonameattribute   = element(var.adc-gw-vserver-authenticationldapaction["ssoNameAttribute"],count.index)
    sectype            = element(var.adc-gw-vserver-authenticationldapaction["secType"],count.index)
    passwdchange       = element(var.adc-gw-vserver-authenticationldapaction["passwdChange"],count.index)

    depends_on = [
        citrixadc_vpnvserver.vpnvserver
    ]
}

resource "citrixadc_authenticationldappolicy" "authenticationldappolicy" {
    count     = length(var.adc-gw-vserver-authenticationldappolicy.name)
    name      = element(var.adc-gw-vserver-authenticationldappolicy["name"],count.index)
    rule      = element(var.adc-gw-vserver-authenticationldappolicy["rule"],count.index)
    reqaction = element(var.adc-gw-vserver-authenticationldappolicy["reqaction"],count.index)

    depends_on = [
        citrixadc_authenticationldapaction.authenticationldapaction
    ]
}

#####
# Bind authentication policies to GW vServer
#####

resource "citrixadc_vpnvserver_authenticationldappolicy_binding" "vpnvserver_authenticationldappolicy_binding" {
    count       = length(var.adc-gw-vserver-authenticationldappolicy_binding.name)
    name        = element(var.adc-gw-vserver-authenticationldappolicy_binding["name"],count.index)
    policy      = element(var.adc-gw-vserver-authenticationldappolicy_binding["policy"],count.index)
    priority    = element(var.adc-gw-vserver-authenticationldappolicy_binding["priority"],count.index)
    bindpoint   = element(var.adc-gw-vserver-authenticationldappolicy_binding["bindpoint"],count.index)
    
    depends_on = [
        citrixadc_authenticationldappolicy.authenticationldappolicy
    ]
}

#####
# Bind SSL certificate to SSL GW vServers
#####

resource "citrixadc_sslvserver_sslcertkey_binding" "sslvserver_sslcertkey_binding_gw" {
    count       = length(var.adc-gw-vserver.name)
    vservername = element(var.adc-gw-vserver["name"],count.index)
    certkeyname = "ssl_cert_goeuc"
    snicert     = true

    depends_on = [
        citrixadc_vpnvserver_authenticationldappolicy_binding.vpnvserver_authenticationldappolicy_binding
    ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "tf_ns_save_gw" {    
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_sslvserver_sslcertkey_binding.sslvserver_sslcertkey_binding_gw
    ]
}