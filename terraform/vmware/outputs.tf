output "dc" {
  value = module.ActiveDirectory.vm_info
}

output "mgnt" {
  value = module.ManagementServer.vm_info
}

# Output for DHCP configuration
output "reverse_dns_zone" {
  value = module.ActiveDirectory.reverse_dns_zone
}

output "dhcp_start_range" {
  value = module.ActiveDirectory.dhcp_start_range
}

output "dhcp_end_range" {
  value = module.ActiveDirectory.dhcp_end_range
}

output "dhcp_subnetmask" {
  value = module.ActiveDirectory.dhcp_subnetmask
}

output "dhcp_router" {
  value = module.ActiveDirectory.dhcp_router
}