output "dc" {
  value = module.windows_workloads["dc"].vm_info
}

output "mgmt" {
  value = module.windows_workloads["mngt"].vm_info
}

output "sql" {
  value = module.windows_workloads["sql"].vm_info
}

output "rd_gateway" {
  value = module.windows_workloads["rdgw"].vm_info
}

output "citrix_cc" {
  value = try(module.windows_workloads["ctx-cc"].vm_info, [])
}

output "citrix_sf" {
  value = try(module.windows_workloads["ctx-sf"].vm_info, [])
}

output "citrix_ddc" {
  value = try(module.windows_workloads["ctx-ddc"].vm_info, [])
}

output "citrix_lic" {
  value = try(module.windows_workloads["ctx-lic"].vm_info, [])
}

output "vmware_hcs" {
  value = try(module.windows_workloads["vmw-hcs"].vm_info, [])
}

output "build" {
  value = module.windows_workloads["build-2022"].vm_info
}

output "bots" {
  value = module.bots.vm_info
}
