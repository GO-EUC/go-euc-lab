# Login Information for the NetScaler to authenticate API calls
variable logon_information {
    type = object({
      username = string
      password = string
      host = string 
    })

}

##############################
# Base NetScaler Configuration
##############################

variable base_configuration {
  description = "uncategorized base_configuration variables"
  type = object({
    hostname = string
    timezone = string
    # Will also be used as Suffix where applicable
    environment_prefix = string
  })
}

variable base_configuration_snip {
  description = "The initial subnet IP information on the NetScaler"
  type = object({
    # NetScaler IP
    ip_address = string
    netmask = string
    icmp = string
  })
}