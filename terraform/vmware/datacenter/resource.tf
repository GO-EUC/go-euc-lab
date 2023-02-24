resource "vsphere_datacenter" "datacenter" {
    name = var.vsphere_datacenter
}

resource "vsphere_compute_cluster" "cluster" {
    name            = var.vsphere_cluster
    datacenter_id   = vsphere_datacenter.datacenter.moid
    host_managed    = true
}

data "vsphere_host_thumbprint" "thumbprints" {
    for_each = data.vault_kv_secret.hosts 
    address = "${jsondecode(data.vault_kv_secret.hosts[each.key].data_json).name}.${jsondecode(data.vault_kv_secret.domain.data_json).name}"
    insecure = true
}

resource "vsphere_host" "esx" {
    for_each = data.vsphere_host_thumbprint.thumbprints

    hostname        = "${jsondecode(data.vault_kv_secret.hosts[each.key].data_json).name}.${jsondecode(data.vault_kv_secret.domain.data_json).name}"
    username        = jsondecode(data.vault_kv_secret.hosts[each.key].data_json).user
    password        = jsondecode(data.vault_kv_secret.hosts[each.key].data_json).password
    cluster         = vsphere_compute_cluster.cluster.id
    thumbprint      = each.value.id
}
