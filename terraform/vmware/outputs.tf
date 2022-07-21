output "dc" {
  value = module.ActiveDirectory.vm_info
}

# Output for DHCP configuration
  output "reverse_dns_zone" {
    value = local.virtual_network_cidr_address[terraform.workspace]
  }

  output "dhcp_start_range" {
    value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 11)
  }

  output "dhcp_end_range" {
    value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 253)
  }

  output "dhcp_subnetmask" {
    value = cidrnetmask(local.virtual_network_cidr_address[terraform.workspace])
  }

  output "dhcp_router" {
    value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 254)
  }