variable "vsphere_datacenter" {
    description = "VMware vSphere datacenter"
    default     = "GO"
    type        = string
}

variable "vsphere_cluster" {
    description = "VMware vSphere datastore"
    default     = "Infra"
    type        = string
}

variable "esx_hosts" {
    type = set(string)
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
