## Local variables uses by resources

locals {
  ad_domain_fqdn                 = "go.euc" #Active Directory Domain Name
  vsphere_datacenter             = "GO"
  vsphere_datastore              = "datastore-infra-02-02"
  vsphere_cluster                = "Infra"
  vsphere_source_template_ws2019 = "server2019-2204.5"
  vsphere_source_template_ubuntu = "ubuntu_test"

  environment_abbreviations = {
    poison       = "pois"
    playing_card = "card"
    flowers      = "flow"
  }

  virtual_network_cidr_address = {
    poison       = "10.10.0.0/16"
    playing_card = "10.20.0.0/16"
    flowers      = "10.30.0.0/16"
  }

  virtual_network_portgroup_name = {
    poison       = "poison"
    playing_card = "card"
    flowers      = "flowers"
  }
}

variable "vsphere_user" {
  description = "VMware vSphere username"
  type        = string
  sensitive   = false
}

variable "vsphere_password" {
  description = "VMware vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "VMware vSphere server"
  type        = string
  sensitive   = false
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
}

variable "domain_admin" {
  description = "Domain administrator to join to the domain"
  type        = string
  sensitive   = false
}

variable "domain_admin_password" {
  description = "Domain administrator password to join to the domain"
  type        = string
  sensitive   = true
}

variable "certificate_file" {
  description = "Certificate file location"
  type        = string
  sensitive   = false
}

variable "certificate_password" {
  description = "Certificate PFX password"
  type        = string
  sensitive   = true
}

variable "certificate_thumbprint" {
  description = "Certificate tumbprint"
  type        = string
  sensitive   = true
}

variable "installsrc_storageaccountsmb" {
  description = "Specify the storageaccount SMB path for the restriced install sources"
  type        = string
}

variable "installsrc_storageaccountusername" {
  description = "Specify the username for accessing storageaccount SMB path for the restriced install sources"
  type        = string
}

variable "installsrc_storageaccountpwd" {
  description = "Specify the password for accessing storageaccount SMB path for the restriced install sources"
  type        = string
}