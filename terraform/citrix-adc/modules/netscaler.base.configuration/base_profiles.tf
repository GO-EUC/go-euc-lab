
# Add basic http Profile
resource "citrixadc_nshttpprofile" "base_http_prof" {
  name = "http_prof_${var.base_configuration.environment_prefix}"
  dropinvalreqs = "ENABLED"
  markhttp09inval = "ENABLED"
  markconnreqinval = "ENABLED"
  weblog = "DISABLED"
  http2 = "ENABLED"
}


# Add basic TCP Profile
resource "citrixadc_nstcpprofile" "base_tcp_prof" {
  name = "tcp_prof_${var.base_configuration.environment_prefix}"
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
# Enable SSL Parameter Usage
#####
resource "citrixadc_sslparameter" "ssl_enable_sslprofiles" {    
  defaultprofile = "ENABLED"
}

#####
# Add SSL Cipher Group Frontend TLS 12+13
#####
resource "citrixadc_sslcipher" "ssl_cg_fe_TLS1213" {
  ciphergroupname = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS1213"

  ciphersuitebinding {
    ciphername     = "TLS1.3-CHACHA20-POLY1305-SHA256"
    cipherpriority = 1
  }
  ciphersuitebinding {
    ciphername     = "TLS1.3-AES256-GCM-SHA384"
    cipherpriority = 2
  }
  ciphersuitebinding {
    ciphername     = "TLS1.3-AES128-GCM-SHA256"
    cipherpriority = 3
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES256-GCM-SHA384"
    cipherpriority = 4
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES128-GCM-SHA256"
    cipherpriority = 5
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES256-GCM-SHA384"
    cipherpriority = 6
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES128-GCM-SHA256"
    cipherpriority = 7
  }

  depends_on = [
    citrixadc_sslparameter.ssl_enable_sslprofiles
  ]
}

# Add SSL Cipher Group Frontend TLS 13
resource "citrixadc_sslcipher" "ssl_cg_fe_TLS13" {
  ciphergroupname = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS13"

  ciphersuitebinding {
    ciphername     = "TLS1.3-CHACHA20-POLY1305-SHA256"
    cipherpriority = 1
  }
  ciphersuitebinding {
    ciphername     = "TLS1.3-AES256-GCM-SHA384"
    cipherpriority = 2
  }
  ciphersuitebinding {
    ciphername     = "TLS1.3-AES128-GCM-SHA256"
    cipherpriority = 3
  }

  depends_on = [
    citrixadc_sslparameter.ssl_enable_sslprofiles
  ]
}

# Add SSL Cipher Group Backend TLS 12
resource "citrixadc_sslcipher" "ssl_cg_be_TLS12" {
  ciphergroupname = "ssl_cg_${var.base_configuration.environment_prefix}_be_TLS12"

  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES256-GCM-SHA384"
    cipherpriority = 1
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES128-GCM-SHA256"
    cipherpriority = 2
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES256-SHA384"
    cipherpriority = 3
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-ECDSA-AES128-SHA256"
    cipherpriority = 4
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES256-GCM-SHA384"
    cipherpriority = 5
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES128-GCM-SHA256"
    cipherpriority = 6
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES-256-SHA384"
    cipherpriority = 7
  }
  ciphersuitebinding {
    ciphername     = "TLS1.2-ECDHE-RSA-AES-128-SHA256"
    cipherpriority = 8
  }

  depends_on = [
    citrixadc_sslparameter.ssl_enable_sslprofiles
  ]
}

# Add SSL Profile Frontend TLS 12+13
resource "citrixadc_sslprofile" "ssl_prof_fe_1213" {
  name = "ssl_prof_${var.base_configuration.environment_prefix}_fe_TLS1213"

  denysslreneg = "NONSECURE"
  ersa         = "DISABLED"
  sessreuse    = "ENABLED"
  sesstimeout  = "120"
  tls1         = "DISABLED"
  tls11        = "DISABLED"
  tls12        = "ENABLED"
  tls13        = "ENABLED"

  cipherbindings {
    ciphername     = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS1213"
    cipherpriority = 10
  }

  ecccurvebindings = [
      "P_521",
      "P_384",
      "P_256",
      "P_224"
  ]

  depends_on = [
    citrixadc_sslcipher.ssl_cg_fe_TLS1213
  ]
}

# Add SSL Profile Frontend TLS 12+13 with SNI
resource "citrixadc_sslprofile" "ssl_prof_fe_1213_SNI" {
  name = "ssl_prof_${var.base_configuration.environment_prefix}_fe_TLS1213_SNI"

  denysslreneg = "NONSECURE"
  ersa         = "DISABLED"
  sessreuse    = "ENABLED"
  sesstimeout  = "120"
  tls1         = "DISABLED"
  tls11        = "DISABLED"
  tls12        = "ENABLED"
  tls13        = "ENABLED"
  snienable    = "ENABLED" 

  cipherbindings {
    ciphername     = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS1213"
    cipherpriority = 10
  }

  ecccurvebindings = [
      "P_521",
      "P_384",
      "P_256",
      "P_224"
  ]

  depends_on = [
    citrixadc_sslcipher.ssl_cg_fe_TLS1213
  ]
}

# Add SSL Profile Frontend TLS 13
resource "citrixadc_sslprofile" "ssl_prof_fe_13" {
  name = "ssl_prof_${var.base_configuration.environment_prefix}_fe_TLS13"

  denysslreneg = "NONSECURE"
  ersa         = "DISABLED"
  sessreuse    = "ENABLED"
  sesstimeout  = "120"
  tls1         = "DISABLED"
  tls11        = "DISABLED"
  tls12        = "DISABLED"
  tls13        = "ENABLED"

  cipherbindings {
    ciphername     = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS13"
    cipherpriority = 10
  }

   ecccurvebindings = [
      "P_521",
      "P_384",
      "P_256",
      "P_224"
  ]

  depends_on = [
    citrixadc_sslcipher.ssl_cg_fe_TLS13
  ]
}

# Add SSL Profile Frontend TLS 13 with SNI
resource "citrixadc_sslprofile" "ssl_prof_fe_13_SNI" {
  name = "ssl_prof_${var.base_configuration.environment_prefix}_fe_TLS13_SNI"

  denysslreneg = "NONSECURE"
  ersa         = "DISABLED"
  sessreuse    = "ENABLED"
  sesstimeout  = "120"
  tls1         = "DISABLED"
  tls11        = "DISABLED"
  tls12        = "DISABLED"
  tls13        = "ENABLED"
  snienable    = "ENABLED" 

  cipherbindings {
    ciphername     = "ssl_cg_${var.base_configuration.environment_prefix}_fe_TLS13"
    cipherpriority = 10
  }

   ecccurvebindings = [
      "P_521",
      "P_384",
      "P_256",
      "P_224"
  ]

  depends_on = [
    citrixadc_sslcipher.ssl_cg_fe_TLS13
  ]
}

# Add SSL Profile Backend TLS 12
resource "citrixadc_sslprofile" "ssl_prof_be_12" {
  name = "ssl_prof_${var.base_configuration.environment_prefix}_be_TLS12"

  denysslreneg   = "NONSECURE"
  ersa           = "DISABLED"
  sessreuse      = "ENABLED"
  sesstimeout    = "300"
  sslprofiletype = "BackEnd"
  tls1           = "DISABLED"
  tls11          = "DISABLED"
  tls12          = "ENABLED"

  cipherbindings {
    ciphername     = "ssl_cg_${var.base_configuration.environment_prefix}_be_TLS12"
    cipherpriority = 10
  }

   ecccurvebindings = [
      "P_521",
      "P_384",
      "P_256",
      "P_224"
  ]

  depends_on = [
    citrixadc_sslcipher.ssl_cg_be_TLS12
  ]     
}

