output "dc" {
  value = module.ActiveDirectory.vm_info
}

output "mgnt" {
  value = module.ManagementServer.vm_info
}

output "fs" {
  value = module.FileServer.vm_info
}

output "rdgw" {
  value = module.RemoteGateway.vm_info
}

output "sql" {
  value = module.SQLServer.vm_info
}

output "ctx_ddc" {
 value = module.CitrixDeliveryControler[*].vm_info
}

output "ctx_lic" {
 value = module.CitrixLicenseServer[*].vm_info
}

output "ctx_sf" {
 value = module.CitrixStorefront[*].vm_info
}

# Output for DHCP configuration
output "reverse_dns_zone" {
  value = local.virtual_network_cidr_address[terraform.workspace]
  depends_on = [ module.ActiveDirectory ]
}

output "dhcp_start_range" {
  value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 11)
  depends_on = [ module.ActiveDirectory ]
}

output "dhcp_end_range" {
  value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 253)
  depends_on = [ module.ActiveDirectory ]
}

output "dhcp_subnetmask" {
  value = cidrnetmask(local.virtual_network_cidr_address[terraform.workspace])
  depends_on = [ module.ActiveDirectory ]
}

output "dhcp_router" {
  value = cidrhost(local.virtual_network_cidr_address[terraform.workspace], 254)
  depends_on = [ module.ActiveDirectory ]
}