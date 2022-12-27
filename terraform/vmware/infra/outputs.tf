output "dc" {
  value = module.domain_controller.vm_info
}

output "mgnt" {
  value = module.management_server.vm_info
}

output "sql" {
  value = module.sql_server.vm_info
}

output "ctx_ddc" {
  value = module.citrix_delivery_controller[*].vm_info
}

output "ctx_lic" {
  value = module.citrix_license_server[*].vm_info
}

output "ctx_sf" {
  value = module.citrix_storefront[*].vm_info
}

output "vmw_vcs" {
  value = module.vmware_connection_server[*].vm_info
}

# output "fs" {
#   value = module.FileServer.vm_info
# }

# output "rdgw" {
#   value = module.RemoteGateway.vm_info
# }



output "lg_bots" {
  value = module.Bots[*].vm_info
}

# Output for DHCP configuration
output "reverse_dns_zone" {
  value      = var.vsphere_nic_cidr
  depends_on = [module.domain_controller]
}

output "dhcp_start_range" {
  value      = cidrhost(var.vsphere_nic_cidr, 20)
  depends_on = [module.domain_controller]
}

output "dhcp_end_range" {
  value      = cidrhost(var.vsphere_nic_cidr, 253)
  depends_on = [module.domain_controller]
}

output "dhcp_subnetmask" {
  value      = cidrnetmask(var.vsphere_nic_cidr)
  depends_on = [module.domain_controller]
}

output "dhcp_router" {
  value      = cidrhost(var.vsphere_nic_cidr, 1)
  depends_on = [module.domain_controller]
}