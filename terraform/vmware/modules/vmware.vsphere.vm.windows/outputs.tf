output "vm_info" {
    value = formatlist("%s ansible_host=%s", vsphere_virtual_machine.vm_static[*].name, vsphere_virtual_machine.vm_static[*].default_ip_address)
}

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