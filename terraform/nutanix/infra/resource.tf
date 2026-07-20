# The golden image is resolved by name straight from the Prism Central image
# library (the Packer templates capture it under this fixed name), so no
# manifest artifact needs to be passed between the image and infra pipelines.
data "nutanix_image" "server_2022" {
  image_name = "windows-server-2022-standard"
}

locals {
  prism_central = jsondecode(data.vault_kv_secret.prism_central.data_json)
  cluster       = jsondecode(data.vault_kv_secret.cluster.data_json)
  network       = jsondecode(data.vault_kv_secret.network.data_json)
  build         = jsondecode(data.vault_kv_secret.build.data_json)
  domain        = jsondecode(data.vault_kv_secret.domain.data_json)

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

  vm_name      = each.key
  vm_cpu       = each.value.cpu
  vm_memory    = each.value.memory
  vm_disk_size = each.value.disk
  cluster_uuid = local.cluster.uuid
  subnet_uuid  = local.network.subnet_uuid
  image_uuid   = data.nutanix_image.server_2022.id

  network_addresses    = [cidrhost(local.network.cidr, var.network_list[each.value.offset])]
  network_prefix       = local.prefix
  network_gateway      = local.gateway
  network_dns          = each.key == "dc" ? [local.default_dns] : [cidrhost(local.network.cidr, var.network_list[0]), local.default_dns]
  local_admin_password = local.build.password
}
