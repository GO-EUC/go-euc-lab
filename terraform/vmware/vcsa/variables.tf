variable "vcsa_template" {
  description = "JSON template file path"
  type = string
  default = "templates/vcsa.json"
}

variable "config_file_path" {
  description = "vcsa configuration JSON file path"
  type = string
  default = "deployment/deploy.json"
}

variable "vcsa_installation" {
  description = "command line file"
  type = string
  default = "/tmp/iso/vcsa-cli-installer/lin64/vcsa-deploy"
}

variable "esx_host" {
  description = "Host address or ip, based on CDIR so 11 will be 10.0.0.11"
  type = number
}

variable "esx_username" {
  description = "Username of the ESX host"
  type = string
}

variable "esx_password" {
  description = "Password of the ESX host"
  type = string
  sensitive = true
}

variable "esx_network" {
  description = "Network to be used on the ESX host"
  type = string
}

variable "esx_datastore" {
  description = "Datastore to be used on the ESX host"
  type = string
}


variable "vcsa_network_cidr" {
  description = "Network cidr"
  type = string
}

variable "vcsa_prefix" {
  description = "IP prefix"
  type = string
}

variable "vcsa_name" {
  description = "VCSA VM name"
  type = string
  default = "vcsa"
}

variable "vcsa_ip" {
  description = "VCSA ip address"
  type = number
}

variable "vcsa_gateway" {
  description = "VCSA gateway"
  type = number
}

variable "vcsa_dns" {
  description = "VCSA dns"
  type = number
}

variable "vcsa_ntp" {
  description = "VCSA NTP server for time, default Dutch time"
  type = string
  default = "nl.pool.ntp.org"
}

variable "vcsa_system_name" {
  description = "VCSA System name, needs to be resolvable"
  type = string
}

variable "vault_address" {
  description = "The vault address in format: http://vault.go.euc:8200"
  type = string
}

variable "vault_token" {
  description = "The vault token that will be used for authtentication"
  type = string
  sensitive = true
}