data "vault_kv_secret" "vcsa" {
    path = "go/vmware/vcsa"
}

data "vault_kv_secret" "network" {
    path = "go/vmware/network"
}

data "vault_kv_secret" "domain" {
    path = "go/domain"
}

data "vault_kv_secret" "hosts" {
    for_each = var.esx_hosts
    path = "go/vmware/esx/${each.value}"
}