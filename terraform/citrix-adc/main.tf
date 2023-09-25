module "vsphere_deployment" {
    # Check if this needs to run based on global settings
    count = var.terraform_settings.deploy_vsphere ? 1 : 0
    # Import the source module
    source = "./modules/vsphere.netscaler.deployment"

    # vSphere settings
    vsphere = var.vsphere

    # VM settings
    vm = var.vm
}


module "base_configuration" {
    # Check if this needs to run based on global settings
    count = var.terraform_settings.deploy_settings ? 1 : 0
    # Import the source module
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

module "letsencrypt" {
    count = var.terraform_settings.deploy_letsencrypt ? 1 : 0
    source = "./modules/netscaler.letsencrypt"

    # LetsEncrypt configuration

    # Set these variables in the module variables.tf file
    # They have been excluded from the main terraform.tfvars file for ease of reading
}

