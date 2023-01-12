#####
# Create Private Key
#####

resource "tls_private_key" "private_key_letsencrypt" {
  algorithm   = var.private_key_algorithm_letsencrypt
  ecdsa_curve = var.private_key_ecdsa_curve_letsencrypt
  rsa_bits    = var.private_key_rsa_bits_letsencrypt
}

#####
# Register with ACME
#####

resource "acme_registration" "registration_letsencrypt" {
  account_key_pem = tls_private_key.private_key_letsencrypt.private_key_pem
  email_address   = var.registration_letsencrypt_email_address

  depends_on = [
    tls_private_key.private_key_letsencrypt
  ]
}

#####
# Create Certificate
#####

resource "acme_certificate" "certificate_letsencrypt" {
  account_key_pem           = acme_registration.registration_letsencrypt.account_key_pem
  common_name               = var.certificate_letsencrypt_common_name
  subject_alternative_names = var.certificate_letsencrypt_subject_alternative_names

  http_challenge {
  }

  depends_on = [
    acme_registration.registration_letsencrypt
  ]
}

#####
# Create Random Number for Naming
#####

resource "random_id" "certandkeyname_letsencrypt" {
  byte_length = 8
}

#####
# Upload files to /ssl at ADC
#####

resource "citrixadc_systemfile" "certificate_pem_letsencrypt" {
  filename = "goeuc_certificate_${lower(random_id.certandkeyname_letsencrypt.hex)}.cer"
  filelocation = var.certificate_pem_letsencrypt_filelocation
  filecontent = lookup(acme_certificate.certificate_letsencrypt, "certificate_pem")

  depends_on = [
    acme_certificate.certificate_letsencrypt,
    random_id.certandkeyname_letsencrypt
  ]
}

resource "citrixadc_systemfile" "privatekey_pem_letsencrypt" {
  filename = "goeuc_privatekey_${lower(random_id.certandkeyname_letsencrypt.hex)}.cer"
  filelocation = var.certificate_pem_letsencrypt_filelocation
  filecontent = nonsensitive(lookup(acme_certificate.certificate_letsencrypt, "private_key_pem"))

  depends_on = [
    acme_certificate.certificate_letsencrypt,
    random_id.certandkeyname_letsencrypt
  ]
}

resource "citrixadc_systemfile" "issuer_pem_letsencrypt" {
  filename = var.issuer_name_letsencrypt
  filelocation = var.certificate_pem_letsencrypt_filelocation
  filecontent = lookup(acme_certificate.certificate_letsencrypt, "issuer_pem")

  depends_on = [
    acme_certificate.certificate_letsencrypt,
    random_id.certandkeyname_letsencrypt
  ]
}

#####
# Implement certificate
#####

resource "citrixadc_sslcertkey" "sslcertkey_letsencrypt" {
  certkey = var.certkey_name_letsencrypt
  cert = "/ssl/goeuc_certificate_${lower(random_id.certandkeyname_letsencrypt.hex)}.cer"
  key = "/ssl/goeuc_privatekey_${lower(random_id.certandkeyname_letsencrypt.hex)}.cer"
  expirymonitor = "DISABLED"

depends_on = [
    citrixadc_systemfile.certificate_pem_letsencrypt,
    citrixadc_systemfile.privatekey_pem_letsencrypt,
    citrixadc_systemfile.issuer_pem_letsencrypt
  ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "ns_save_letsencrypt" {  
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_sslcertkey.sslcertkey_letsencrypt
    ]
}