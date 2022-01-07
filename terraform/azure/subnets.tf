#vNet with peerings is imported in "Azure_vnet_import.tf"

resource "azurerm_subnet" "backend" {
  name                                           = "sn-infra-${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name                            = azurerm_resource_group.VNet.name
  virtual_network_name                           = azurerm_virtual_network.AzurevNet.name
  address_prefixes                               = [local.infra_subnet_cidr[terraform.workspace]]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "docker" {
  name                 = "sn-docker-${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name  = azurerm_resource_group.VNet.name
  virtual_network_name = azurerm_virtual_network.AzurevNet.name
  address_prefixes     = [local.docker_subnet_cidr[terraform.workspace]]


  delegation {
    name = "dl-docker-${local.environment_abbreviations[terraform.workspace]}"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_network_profile" "docker" {
    name                = "np-docker-${local.environment_abbreviations[terraform.workspace]}"
    location            = azurerm_resource_group.VNet.location
    resource_group_name  = azurerm_resource_group.VNet.name

    container_network_interface {
        name = "nic-docker-${local.environment_abbreviations[terraform.workspace]}"

        ip_configuration {
            name      = "ip-docker-${local.environment_abbreviations[terraform.workspace]}"
            subnet_id = azurerm_subnet.docker.id
        }
    }
}


resource "azurerm_subnet" "bastion" {
  name                                           = "AzureBastionSubnet"
  resource_group_name                            = azurerm_resource_group.VNet.name
  virtual_network_name                           = azurerm_virtual_network.AzurevNet.name
  address_prefixes                               = [local.bastion_subnet_cidr[terraform.workspace]]
  enforce_private_link_endpoint_network_policies = true
}

