#####
# Variable for administrative connection to the ADC
#####
variable vm {}
variable adc-base {}
variable adc-snip {}

#####
# Variable for license file upload
#####
variable adc-license {}

#####
# ADC Loadbalancing Server
#####
variable adc-lb {}
variable adc-lb-srv {}
variable adc-lb-generic {}

#####
# Variable for LetsEncrypt Loadbalabcing configuration
#####
variable adc-letsencrypt-lb {}

#####
# Variables for configuring the certificate
#####
variable adc-letsencrypt-certificate {}
variable adc-letsencrypt-certificate-san{}

#####
# ADC GW vServer
#####
variable "adc-gw" {}
variable "adc-gw-authenticationldapaction" {}
variable "adc-gw-authenticationldappolicy" {}

#####
# Functional Variables
#####
variable adc-finish {}

#####
# Variables
#####
variable adc-cs {}
variable adc-cs-lb {}
variable adc-cs-gw {}