#####
# Defince locals
#####
locals {
  filelocation = "/nsconfig/ssl"
}

#####
# Create Private Key
#####
resource "tls_private_key" "le_private_key" {
  algorithm   = var.adc-letsencrypt-certificate.private_key_algorithm
  ecdsa_curve = var.adc-letsencrypt-certificate.private_key_ecdsa_curve
  rsa_bits    = var.adc-letsencrypt-certificate.private_key_rsa_bits
}

#####
# Register with ACME
#####
resource "acme_registration" "le_registration" {
  account_key_pem = tls_private_key.le_private_key.private_key_pem
  email_address   = var.adc-letsencrypt-certificate.registration_email_address

  depends_on = [
    tls_private_key.le_private_key
  ]
}

#####
# Create Certificate
#####
resource "acme_certificate" "le_certificate" {
  account_key_pem           = acme_registration.le_registration.account_key_pem
  common_name               = "${var.adc-letsencrypt-certificate.common_name}.${var.adc-base.fqdn_ext}"
  subject_alternative_names = var.adc-letsencrypt-certificate-san

  http_challenge {
  }

  depends_on = [
    acme_registration.le_registration
  ]
}

#####
# Upload cert files to /nsconfig/ssl on ADC
#####
resource "citrixadc_systemfile" "le_upload_cert" {
  filename = "${var.adc-base.environmentname}_certificate.cer"
  filelocation = local.filelocation
  filecontent = lookup(acme_certificate.le_certificate,"certificate_pem")

  depends_on = [
    acme_certificate.le_certificate
  ]
}

resource "citrixadc_systemfile" "le_upload_key" {
  filename = "${var.adc-base.environmentname}_privatekey.cer"
  filelocation = local.filelocation
  filecontent = nonsensitive(lookup(acme_certificate.le_certificate,"private_key_pem"))

  depends_on = [
    acme_certificate.le_certificate
  ]
}

resource "citrixadc_systemfile" "le_upload_root" {
  filename = "${var.adc-base.environmentname}_rootca.cer"
  filelocation = local.filelocation
  filecontent = lookup(acme_certificate.le_certificate,"issuer_pem")

  depends_on = [
    acme_certificate.le_certificate
  ]
}

#####
# Implement root certificate
#####
resource "citrixadc_sslcertkey" "le_implement_rootca" {
  certkey = "ssl_cert_${var.adc-base.environmentname}_RootCA"
  cert = "/nsconfig/ssl/${var.adc-base.environmentname}_rootca.cer"
  expirymonitor = "DISABLED"

depends_on = [
    citrixadc_systemfile.le_upload_cert,
    citrixadc_systemfile.le_upload_key
  ]
}

#####
# Implement server certificate
#####
resource "citrixadc_sslcertkey" "le_implement_certkeypair" {
  certkey = "ssl_cert_${var.adc-base.environmentname}_Server"
  cert = "/nsconfig/ssl/${var.adc-base.environmentname}_certificate.cer"
  key = "/nsconfig/ssl/${var.adc-base.environmentname}_privatekey.cer"
  expirymonitor = "DISABLED"
  linkcertkeyname = "ssl_cert_${var.adc-base.environmentname}_RootCA"

  depends_on = [
    citrixadc_sslcertkey.le_implement_rootca
  ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "le_save" {  
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_sslcertkey.le_implement_certkeypair,
        citrixadc_sslcertkey.le_implement_rootca
    ]
}