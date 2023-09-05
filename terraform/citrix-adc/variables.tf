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
    subnet_ip = string
    netmask = string
    icmp = string
  })
}

# All backend services to be created
variable backend_services {
  description = "All backend services to be created"
  type = map(object({
    hostname = string
    ip = string
  }))
}

# All service groups to be created
variable service_groups {
  description = "All service groups to be created"
  type        = map(object({
    name = string
    type = string
    port = string
    backend_services = list
  }))
}

# All virtual servers to be created
variable virtual_servers {
  description = "All virtual servers to be created"
  type        = map(object({
    name = string
    type = string
    port = string
    lb_type = string
    service_groups = list
  }))
}
