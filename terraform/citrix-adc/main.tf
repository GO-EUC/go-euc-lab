module "base_configuration" {
    source = "./modules/netscaler.base.configuration"

    # Default settings / Best Practices & Profiles
    # base_configuration.tf
    logon_information = var.logon_information
    base_configuration = var.base_configuration
    base_configuration_snip = var.base_configuration_snip



    # Virtual Servers / Services creation
    # base_vservers.tf
    servers = var.servers
    service_groups = var.service_groups
    virtual_servers = var.virtual_servers

    #LDAP (advanced) authentication with global binding
    # base_ldaps.tf
    auth_ldaps = var.auth_ldaps

    #Gateway configuration
    # base_gateway.tf
    gateway = var.gateway



    
}