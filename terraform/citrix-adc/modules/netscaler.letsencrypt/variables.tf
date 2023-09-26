# ADC LetsEncrypt LB configuration variables
variable "letsencrypt_lb" {
  type        = map(any)
  description = "LetsEncrypt LoadBalancer configuration variables"
  default = {
    backend-ip            = "192.168.1.25"
    frontend-ip           = "192.168.1.17"
    servicetype           = "TCP"
    port                  = "80"
    lb_srv_name           = "lb_srv_letsencrypt_backend"
    lb_sg_name            = "lb_sg_letsencrypt_backend"
    lb_sg_healthmonitor   = "NO"
    lb_vs_name            = "lb_vs_letsencrypt"
    lb_vs_lbmethod        = "LEASTCONNECTION"
    lb_vs_persistencetype = "SOURCEIP"
    lb_vs_timeout         = "2"
  }
}

# ADC LetsEncrypt configuration variables
variable "letsencrypt_certificate" {
  type        = map(any)
  description = "Lets Encrypt Certificate configuration variables"
  default = {
    private_key_algorithm      = "RSA"
    private_key_rsa_bits       = "4096"
    private_key_ecdsa_curve    = "P224"
    registration_email_address = "you@something.com"
    common_name                = "environment.com"

  }
}

variable "letsencrypt_certificate-san" {
  type = list(any)
  default = [
    "citrix.YourEnvironment.YourDomain.YourTLD"
  ]
}

