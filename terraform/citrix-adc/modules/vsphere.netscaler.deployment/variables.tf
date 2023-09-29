variable "vsphere" {
  description = "values for the creation of a NetScaler VM"
  type = object({
    # Subnet IP
    server       = string
    user         = string
    password     = string
    datacenter   = string
    host         = string
    datastore    = string
    network      = string
    timezone     = string
    resourcepool = string
  })
}

variable "vm" {
  description = "values for the creation of a NetScaler VM"
  type = object({
    # Subnet IP
    ovf     = string
    network = string
    mac     = string
    ip      = string
    gateway = string
    netmask = string
    name    = string
  })
}
