locals {
  prism   = jsondecode(data.vault_kv_secret.prism.data_json)
  cluster = jsondecode(data.vault_kv_secret.cluster.data_json)
  network = jsondecode(data.vault_kv_secret.network.data_json)
  build   = jsondecode(data.vault_kv_secret.build.data_json)
  domain  = jsondecode(data.vault_kv_secret.domain.data_json)

  server_2022 = jsondecode(file("${var.root_path}/manifests/windows-server-2022-standard.json")).builds[0].artifact_id
  adapter     = "${var.root_path}/scripts/nutanix/Invoke-PrismElement.ps1"
  prefix      = tonumber(split("/", local.network.cidr)[1])
  gateway     = cidrhost(local.network.cidr, local.network.gateway)
  default_dns = cidrhost(local.network.cidr, local.network.dns)

  workloads = merge({
    dc         = { offset = 0, cpu = 4, memory = 4096, disk = 100 }
    mngt       = { offset = 1, cpu = 4, memory = 4096, disk = 512 }
    sql        = { offset = 2, cpu = 4, memory = 4096, disk = 256 }
    rdgw       = { offset = 15, cpu = 4, memory = 4096, disk = 100 }
    build-2022 = { offset = 3, cpu = 4, memory = 16384, disk = 128 }
    },
    var.citrix_cloud ? {
      ctx-cc = { offset = 4, cpu = 4, memory = 4096, disk = 100 }
    } : {},
    var.citrix_vad ? {
      ctx-ddc = { offset = 5, cpu = 4, memory = 4096, disk = 100 }
      ctx-sf  = { offset = 6, cpu = 4, memory = 4096, disk = 100 }
      ctx-lic = { offset = 7, cpu = 4, memory = 4096, disk = 100 }
    } : {},
    var.vmware_horizon ? {
      vmw-hcs = { offset = 8, cpu = 4, memory = 4096, disk = 100 }
    } : {}
  )
}

module "windows_workloads" {
  for_each = local.workloads
  source   = "./modules/nutanix.vm.windows"

  vm_name        = each.key
  vm_cpu         = each.value.cpu
  vm_memory      = each.value.memory
  vm_disk_size   = each.value.disk
  prism_endpoint = local.prism.endpoint
  prism_username = local.prism.username
  prism_password = local.prism.password
  # Vault stores every kv value as a string and the initializer writes the
  # PowerShell boolean as "True", which Terraform cannot convert directly.
  prism_insecure = lower(tostring(local.prism.insecure)) == "true"
  cluster_uuid   = local.cluster.uuid
  subnet_uuid    = local.network.subnet_uuid
  image_uuid     = local.server_2022
  adapter_path   = local.adapter

  network_addresses    = [cidrhost(local.network.cidr, var.network_list[each.value.offset])]
  network_prefix       = local.prefix
  network_gateway      = local.gateway
  network_dns          = each.key == "dc" ? [local.default_dns] : [cidrhost(local.network.cidr, var.network_list[0]), local.default_dns]
  local_admin_password = local.build.password
}
