locals {
  images = [
    {
      name  = "windows-11"
      json  = "${var.root_path}/manifests/windows-desktop-11.json"
      guest = "windows9_64Guest"
    },
    {
      name  = "windows-10"
      json  = "${var.root_path}/manifests/windows-desktop-10.json"
      guest = "windows9_64Guest"
    },
    {
      name  = "server-2025"
      json  = "${var.root_path}/manifests/windows-server-2025-standard.json"
      guest = "windows2019srv_64Guest"
    },
    {
      name  = "server-2022"
      json  = "${var.root_path}/manifests/windows-server-2022-standard.json"
      guest = "windows2019srv_64Guest"
    },
    {
      name  = "server-2019"
      json  = "${var.root_path}/manifests/windows-server-2019-standard.json"
      guest = "windows2019srv_64Guest"
    }
  ]

  template = jsondecode(file(local.images[index(local.images[*].name, var.windows_template)].json))
  guest_id = local.images[index(local.images[*].name, var.windows_template)].guest

  vsphere_server   = cidrhost(jsondecode(data.vault_kv_secret.network.data_json).cidr, jsondecode(data.vault_kv_secret.vcsa.data_json).ip)
  vsphere_user     = jsondecode(data.vault_kv_secret.vcsa.data_json).user
  vsphere_password = jsondecode(data.vault_kv_secret.vcsa.data_json).password

  # Note, the first host will be used to the primary deployments
  vsphere_nic       = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[1]].data_json).network
  vsphere_datastore = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[1]].data_json).datastore

  vsphere_datastore_build = jsondecode(data.vault_kv_secret.esxs[data.vault_kv_secrets_list.esx.names[1]].data_json).datastore

  domain         = jsondecode(data.vault_kv_secret.domain.data_json).name
  build_password = jsondecode(data.vault_kv_secret.build.data_json).password
}