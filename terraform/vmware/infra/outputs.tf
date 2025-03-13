output "dc" {
  value = module.domain_controller[*].vm_info
}

output "mgmt" {
  value = module.management_server[*].vm_info
}

output "sql" {
  value = module.sql_server[*].vm_info
}

output "rd_gateway" {
  value = module.rd_gateway[*].vm_info
}

output "citrix_cc" {
  value = module.citrix_cloud_connectors[*].vm_info
}

output "citrix_sf" {
  value = module.citrix_storefront[*].vm_info
}

output "citrix_ddc" {
  value = module.citrix_delivery_controller[*].vm_info
}

output "citrix_lic" {
  value = module.citrix_license_server[*].vm_info
}

output "bots" {
  value = module.bots[*].vm_info
}

output "vmware_hcs" {
  value = module.vmware_horizon[*].vm_info
}

output "vcsa" {
  value = nonsensitive(formatlist("%s ansible_host=%s", jsondecode(data.vault_kv_secret.vcsa.data_json).name, cidrhost(local.nic_cidr, jsondecode(data.vault_kv_secret.vcsa.data_json).ip)))
}