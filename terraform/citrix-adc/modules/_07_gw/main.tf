#####
# Add Citrix Gateway
#####

resource "citrixadc_vpnvserver" "vpnvserver" {
    count                       = length(var.adc-gw-vserver.name)
    name                        = element(var.adc-gw-vserver["name"],count.index)
    servicetype                 = element(var.adc-gw-vserver["servicetype"],count.index)
    ipv46                       = element(var.adc-gw-vserver["ipv46"],count.index)
    port                        = element(var.adc-gw-vserver["port"],count.index)
    dtls                        = element(var.adc-gw-vserver["dtls"],count.index)
    tcpprofilename              = element(var.adc-gw-vserver["tcpprofilename"],count.index)
    httpprofilename             = element(var.adc-gw-vserver["httpprofilename"],count.index)
    appflowlog                  = element(var.adc-gw-vserver["appflowlog"],count.index)
}

#####
# Bind SSL profile to GW vServer
#####

resource "citrixadc_sslvserver" "sslvserver" {
    count       = length(var.adc-gw-vserver.name)
    vservername = citrixadc_vpnvserver.vpnvserver[count.index].name
    sslprofile  = "ssl_prof_goeuc_fe_TLS1213"
}


#####
# Bind STA Servers to GW vServer
#####

resource "citrixadc_vpnvserver_staserver_binding" "tf_binding" {
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

resource "citrixadc_vpnvserver_vpnsessionpolicy_binding" "tf_bind" {
    count     = length(var.adc-gw-vserver-vpnsessionpolicybinding.name)
    name      = element(var.adc-gw-vserver-vpnsessionpolicybinding["name"],count.index)
    policy    = element(var.adc-gw-vserver-vpnsessionpolicybinding["policy"],count.index)
    priority  = element(var.adc-gw-vserver-vpnsessionpolicybinding["priority"],count.index)

    depends_on = [
        citrixadc_vpnsessionpolicy.vpnsessionpolicy_receiver_web,
        citrixadc_vpnsessionpolicy.vpnsessionpolicy_receiver_web
    ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "tf_ns_save" {
    
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_vpnvserver_vpnsessionpolicy_binding.tf_bind
    ]

}