locals {
    #naming vars
    environment_abbreviations = {
        default         = "pois"
        main            = "card"
        develop         = "flow"
    }

    #deployementname
    deploymentname = "golab"
    ad_domain_fqdn = "go.euc"  #Active Directory Domain Name
    

    #geographical details about Azure Datacenter
    azure_location = "westeurope"


    #network locals
    infra_subnet_cidr = {
        default         = "10.100.200.0/24"
        main            = "10.100.201.0/24"
        develop         = "10.100.202.0/24"
    }

    bastion_subnet_cidr = {
        default         = "10.100.24.0/24"
        main            = "10.100.25.0/24"
        develop         = "10.100.26.0/24"
    }


    #please specify existing network info, which is imported with data
    #the Azure DevOps agent with Ansible need WinRM access to private IP
    import_vnet_name            = "PBO-VNET-MP"
    import_vnet_resourcegroup   = "WVD-LABEU"
    import_vnet_subnetname      = "WVD-SN"
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