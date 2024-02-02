
# Set NS Hostname
resource "citrixadc_nshostname" "base_hostname" {
  hostname = var.base_configuration.hostname
}


# Add NetScaler IP
resource "citrixadc_nsip" "base_snip" {
  ipaddress = var.base_configuration_snip.ip_address
  netmask   = var.base_configuration_snip.netmask
  icmp      = var.base_configuration_snip.icmp
  type      = "SNIP"
}


# Configure ADC timezone
resource "citrixadc_nsparam" "base_nsparam" {
  timezone = var.base_configuration.timezone
}


# Configure Modes
resource "citrixadc_nsmode" "base_nsmode" {
  bridgebpdus         = false
  cka                 = false
  dradv               = false
  dradv6              = false
  edge                = true
  fr                  = true
  iradv               = false
  l2                  = false
  l3                  = false
  mbf                 = false
  mediaclassification = false
  pmtud               = true
  sradv               = false
  sradv6              = false
  tcpb                = false
  ulfd                = false
  usnip               = true
  usip                = false
}


# Configure Features
resource "citrixadc_nsfeature" "advanced_nsfeature" {
  aaa                = var.base_configuration.advanced
  adaptivetcp        = false
  apigateway         = false
  appflow            = false
  appfw              = false
  appqoe             = false
  bgp                = false
  bot                = false
  cf                 = false
  ch                 = false
  ci                 = false
  cloudbridge        = false
  cmp                = false
  contentaccelerator = false
  cqa                = false
  cr                 = false
  cs                 = true
  feo                = false
  forwardproxy       = false
  gslb               = false
  hdosp              = false
  ic                 = false
  ipv6pt             = false
  isis               = false
  lb                 = true
  lsn                = false
  ospf               = false
  pq                 = false
  push               = false
  rdpproxy           = false
  rep                = false
  responder          = true
  rewrite            = true
  rip                = false
  rise               = false
  sp                 = false
  ssl                = true
  sslinterception    = false
  sslvpn             = var.base_configuration.advanced
  urlfiltering       = false
  videooptimization  = false
  wl                 = false
}



resource "citrixadc_systemparameter" "base_systemparam" {
  strongpassword = "enableall"
}


# # Save config
# resource "citrixadc_nsconfig_save" "base_save" {  
#   all  = true
#   timestamp  = timestamp()

#   depends_on = [
#     citrixadc_nsconfig_save.base_save,
#     citrixadc_nsfeature.advanced_nsfeature,
#     citrixadc_nshostname.base_hostname,
#     citrixadc_nsip.base_snip,
#     citrixadc_nsmode.base_nsmode,
#     citrixadc_nsparam.base_nsparam,
#     citrixadc_systemparameter.base_systemparam,
#     citrixadc_sslvserver.gw_vserver_sslprofile
#   ]
# }
