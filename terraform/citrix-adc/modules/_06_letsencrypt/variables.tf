#####
# Variables for administrative connection to the ADC
#####

variable adc-base-username {
  description = "ADC username"
  type        = string
  default     = "nsroot"
}

variable adc-base-password {
  description = "ADC password"
  type        = string
  default     = ""
}

variable adc-base-ip-mgmt-address {
  description = "ADC mgmt IP address"
  type        = string
  default     = ""
}

#####
# Variables for configuring the private key
#####

variable private_key_algorithm_letsencrypt{
  type = string
  description = "Private Key algorithm for LetsEncrypt certificate generation"
  default = ""
}

variable private_key_ecdsa_curve_letsencrypt{
  type = string
  description = "Private Key ecdsa curve for LetsEncrypt certificate generation"
  default = ""
}

variable private_key_rsa_bits_letsencrypt{
  type = string
  description = "Private Key rsa bits for LetsEncrypt certificate generation"
  default = ""
}

#####
# Variables for the LetsEncrypt registration
#####

variable registration_letsencrypt_email_address{
  type = string
  description = "E-Mail Address for LetsEncrypt registration"
  default = ""
}

#####
# Variables for configuring the certificate
#####

variable certificate_letsencrypt_common_name{
  type = string
  description = "Common name for your server certificate"
  default = ""
}

variable certificate_letsencrypt_subject_alternative_names{
  description = "SAN names for your server certificate"
  default = [
    "",
    "",
    ""]
}

#####
# Variables for certificate file upload
#####

variable certificate_pem_letsencrypt_filelocation{
  type = string
  description = "Certificate target folder on ADC"
  default = "/ssl"
}

variable issuer_name_letsencrypt{
  type = string
  description = "The RootCA certificate name"
  default = ""
}

#####
# Variable for certificate installation on ADC
#####

variable certkey_name_letsencrypt{
  type = string
  description = "The certkeyname taht will be displayed and used on ADC"
  default = ""
}