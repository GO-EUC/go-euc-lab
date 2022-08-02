#####
# Add IP addresses
#####

resource "citrixadc_nsip" "nsip" {
    count      = length(var.adc-base-ip.ipaddress)
    ipaddress  = element(var.adc-base-ip["ipaddress"],count.index)
    netmask    = element(var.adc-base-ip["netmask"],count.index)
    type       = element(var.adc-base-ip["type"],count.index)
    icmp       = element(var.adc-base-ip["icmp"],count.index)
}

#####
# Configure the ADC timezone / ToDo: Getting "ambigous" error
#####

#resource "citrixadc_nsparam" "nsparam" {
#  timezone = var.adc-base-timezone
#}

#####
# Configure Modes / Static for now
#####

resource "citrixadc_nsmode" "nsmode" {
    bridgebpdus = false
    cka = false
    dradv = false
    dradv6 = false
    edge = true
    fr = true
    iradv = false
    l2 = false
    l3 = false
    mbf = false
    mediaclassification = false
    pmtud = true
    sradv = false
    sradv6 = false
    tcpb = false
    ulfd = false
    usnip = true
    usip = false
}

#####
# Configure Features / Static for now
#####

resource "citrixadc_nsfeature" "nsfeature" {
    aaa = true
    adaptivetcp = false
    apigateway = false
    appflow = false
    appfw = false
    appqoe = false
    bgp = false
    bot = false
    cf = false
    ch = false
    ci = false
    cloudbridge = false
    cmp = false
    contentaccelerator = false
    cqa = false
    cr = false
    cs = true
    feo = false
    forwardproxy = false
    gslb = false
    hdosp = false
    ic = false
    ipv6pt = false
    isis = false
    lb = true
    lsn = false
    ospf = false
    pq = false
    push = false
    rdpproxy = false
    rep = false
    responder = true
    rewrite = true
    rip = false
    rise = false
    sp = false
    ssl = true
    sslinterception = false
    sslvpn = true
    urlfiltering = false
    videooptimization = false
    wl = false
}

#####
# Add a http Profile  / Static for now
#####

resource "citrixadc_nshttpprofile" "http_prof_democloud" {
    name = "http_prof_democloud"
    dropinvalreqs = "ENABLED"
    markhttp09inval = "ENABLED"
    markconnreqinval = "ENABLED"
    weblog = "DISABLED"

}

#####
# Add a TCP Profile  / Static for now
#####

resource "citrixadc_nstcpprofile" "tcp_prof_democloud" {
    name = "tcp_prof_democloud"
    ws = "ENABLED"
    sack = "ENABLED"
    wsval = "8"
    mss = "1460"
    initialcwnd = "10"
    oooqsize = "300"
    buffersize = "131072"
    flavor = "BIC"
    sendbuffsize = "131072"
    rstmaxack = "ENABLED"
    spoofsyndrop = "DISABLED"
    frto = "ENABLED"
    fack = "ENABLED"
    nagle = "ENABLED"
    dynamicreceivebuffering = "ENABLED"
    drophalfclosedconnontimeout = "ENABLED"
    dropestconnontimeout = "ENABLED"
}

#####
# Save config - Only if all previous resources have been created successfully.
#####

resource "citrixadc_nsconfig_save" "ns_save_base" {    
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_nsip.nsip,
        citrixadc_nsmode.nsmode,
        citrixadc_nsfeature.nsfeature,
        citrixadc_nshttpprofile.http_prof_democloud,
        citrixadc_nstcpprofile.tcp_prof_democloud
    ]
}