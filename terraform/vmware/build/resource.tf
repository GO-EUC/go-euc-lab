locals {
  # template_windows_2019 = jsondecode(file("${var.root_path}/manifests/windows-server-2019-standard.json"))
  # template_windows_2022 = jsondecode(file("${var.root_path}/manifests/windows-server-2022-standard.json"))
  # template_windows_2025 = jsondecode(file("${var.root_path}/manifests/windows-server-2025-standard.json"))

  template_windows_11 = jsondecode(file("${var.root_path}/manifests/windows-desktop-11.json"))
  # template_windows_10 = jsondecode(file("${var.root_path}/manifests/windows-desktop-10.json"))


  vsphere_server   = cidrhost(jsondecode(data.vault_kv_secret.network.data_json).cidr, jsondecode(data.vault_kv_secret.vcsa.data_json).ip)
  vsphere_user     = jsondecode(data.vault_kv_secret.vcsa.data_json).user
  vsphere_password = jsondecode(data.vault_kv_secret.vcsa.data_json).password

  # Note, the first host will be used to the primary deployments
  vsphere_nic       = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[0]].data_json).network
  vsphere_datastore = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[0]].data_json).datastore

  vsphere_datastore_build = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[1]].data_json).datastore

  domain         = jsondecode(data.vault_kv_secret.domain.data_json).name
  build_password = jsondecode(data.vault_kv_secret.build.data_json).password
}

module "build" {
  source = "../modules/vmware.vsphere.vm.windows"

  vsphere_server   = local.vsphere_server
  vsphere_user     = local.vsphere_user
  vsphere_password = local.vsphere_password

  vm_name               = var.build_name
  vm_cpu                = 4
  vm_memory             = 16384
  vm_guest_id           = "windows9_64Guest"
  local_admin_password  = local.build_password

  domain                = local.domain
  domain_admin          = var.domain_admin
  domain_admin_password = local.build_password

  virtual_network_portgroup_name = local.vsphere_nic

  vsphere_datacenter      = var.vsphere_datacenter
  vsphere_datastore       = local.vsphere_datastore
  vsphere_cluster         = var.vsphere_cluster
  vsphere_source_template = local.template_windows_11.builds[0].artifact_id
}