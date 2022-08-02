#####
# Add Content Switching Actions
#####

resource "citrixadc_csaction" "cs_act_gw-democloud-devicetrust-com" {

  name            = "cs_act_gw-democloud-devicetrust-com"
  targetvserver = "gw_vs_gw-democloud-local_ssl_443"

}

resource "citrixadc_csaction" "cs_act_guac-democloud-devicetrust-com" {

  name            = "cs_act_guac-democloud-devicetrust-com"
  targetlbvserver  = "lb_vs_guac-democloud-local_ssl_443"

}

resource "citrixadc_csaction" "cs_act_icg-democloud-devicetrust-com" {

  name            = "cs_act_icg-democloud-devicetrust-com"
  targetlbvserver  = "lb_vs_icg-democloud-local_ssl_443"

}

#####
# Add Content Switching Policies
#####

resource "citrixadc_cspolicy" "cs_pol_gw-democloud-devicetrust-com" {
  policyname      = "cs_pol_gw-democloud-devicetrust-com"
  rule            = "HTTP.REQ.HOSTNAME.CONTAINS('gw.democloud.devicetrust.com')"
  priority        = 10

  depends_on  = [
    citrixadc_csaction.cs_act_gw-democloud-devicetrust-com
  ]

}

resource "citrixadc_cspolicy" "cs_pol_guac-democloud-devicetrust-com" {
  policyname      = "cs_pol_guac-democloud-devicetrust-com"
  rule            = "HTTP.REQ.HOSTNAME.CONTAINS('guac.democloud.devicetrust.com')"
  priority        = 20

  depends_on  = [
    citrixadc_csaction.cs_act_guac-democloud-devicetrust-com
  ]

}

resource "citrixadc_cspolicy" "cs_pol_icg-democloud-devicetrust-com" {
  policyname      = "cs_pol_icg-democloud-devicetrust-com"
  rule            = "HTTP.REQ.HOSTNAME.CONTAINS('icg.democloud.devicetrust.com')"
  priority        = 30

  depends_on  = [
    citrixadc_csaction.cs_act_icg-democloud-devicetrust-com
  ]

}

#####
# Add Content Switching vServer
#####
resource "citrixadc_csvserver" "cs_vs_any-democloud-local_ssl_443" {
  ipv46             = "10.10.10.12"
  name              = "cs_vs_any-democloud-local_ssl_443"
  port              = 443
  servicetype       = "SSL"

  depends_on  = [
    citrixadc_csaction.cs_act_gw-democloud-devicetrust-com,
    citrixadc_csaction.cs_act_guac-democloud-devicetrust-com,
    citrixadc_cspolicy.cs_pol_icg-democloud-devicetrust-com
  ]

}

#####
# Bind Content Switching Policies to Content Switching vServer
#####

resource "citrixadc_csvserver_cspolicy_binding" "csvscspolbind" {
    name = citrixadc_csvserver.cs_vs_any-democloud-local_ssl_443.name
    policyname = "cs_pol_icg-democloud-devicetrust-com"
    priority = 100

  depends_on  = [
    citrixadc_csvserver.cs_vs_any-democloud-local_ssl_443
  ]
}