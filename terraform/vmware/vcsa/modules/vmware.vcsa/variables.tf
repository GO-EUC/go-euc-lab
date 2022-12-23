variable "vcsa_template" {
  description = "JSON template file path"
  type = string
  default = "modules/vmware.vcsa/templates/vcsa.json"
}

variable "config_file_path" {
  description = "vcsa configuration JSON file path"
  type = string
  default = "modules/vmware.vcsa/deployment/deploy.json"
}

variable "vcsa_installation" {
  description = "command line file"
  type = string
  default = "C:\\Software\\VMware\\VCSA_703\\vcsa-cli-installer\\win32\\vcsa-deploy.exe"
}

variable "esx_host" {
  description = "Host address or ip"
  type = string
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

variable "vcsa_password" {
  description = "VCSA password"
  type = string
  sensitive = true
}

variable "vcsa_name" {
  description = "VCSA VM name"
  type = string
  default = "vcsa"
}

variable "vcsa_ip" {
  description = "VCSA ip address"
  type = string
}

variable "vcsa_prefix" {
  description = "IP prefix"
  type = string
}

variable "vcsa_gateway" {
  description = "VCSA gateway"
  type = string
}

variable "vcsa_dns" {
  description = "VCSA dns"
  type = string
}

variable "vcsa_ntp" {
  description = "VCSA NTP server for time, default Dutch time"
  type = string
  default = "nl.pool.ntp.org"
}



