# Login Information for the NetScaler to authenticate API calls
variable logon_information {
  description = "The logon information to authenticate the NetScaler API calls with"
    type = object({
      username = string
      password = string
      host = string 
    })
}

variable base_configuration {
  description = "uncategorized base_configuration variables"
  type = object({
    hostname = string
    timezone = string
    # Will also be used as Suffix where applicable
    environment_prefix = string
    # Deploy advanced features (if licensed with advanced or above only!) 
    advanced = bool

  })
}

variable base_configuration_snip {
  description = "The first subnet IP information on the NetScaler"
  type = object({
    # Subnet IP
    ip_address = string
    netmask = string
    icmp = string
  })
}


# All backend servers to be created
variable servers {
  description = "All backend servers to be created"
  type = map(object({
    hostname = string
    ip_address = string
  }))
}

# All service groups to be created
variable service_groups {
  description = "All service groups to be created"
  type        = map(object({
    name = string
    type = string
    port = string
    # Define backend servers: Name + port + weight
    servers_to_bind = list(string)
    # Define the virtual servers to bind this service group to:
    virtual_server_bindings = list(string)
  }))
}

# All virtual servers to be created
variable virtual_servers {
  description = "All virtual servers to be created"
  type        = map(object({
    name = string
    ipv46 = string
    port = string
    lbmethod = string
    persistencetype = string
    timeout = string
    servicetype = string
    sslprofile = optional(string)
    httpprofilename = optional(string)
    tcpprofilename = optional(string)
  }))

}

variable auth_ldaps {
  description = "Values to setup base (advanced) authentication policy / action"
  type = object({
    policy_name = string
    action_name = string
    policy_expression = string
    serverip = string
    serverport = string
    sectype = string
    authtimeout = string
    ldaploginname = string
    ldapbase = optional(string)
    ldapbinddn = optional(string)
    ldapbinddnpassword = optional(string)
  })
}

variable gateway{
  description = "Values to create default gateway vserver"
  type = object({
    name = string
    servicetype     = string
    ipv46           = string
    port            = string
    dtls            = string
    sta             = string
    storefronturl   = string
  })
}

