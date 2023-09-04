module "base_configuration" {
    source = "./modules/netscaler.base.configuration"
    logon_information = var.logon_information
    base_configuration = var.base_configuration
    base_configuration_snip = var.base_configuration_snip
}