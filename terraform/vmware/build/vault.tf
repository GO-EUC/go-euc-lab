data "vault_kv_secret" "domain" {
  path = "go/domain"
}

data "vault_kv_secret" "build" {
  path = "go/build"
}

data "vault_kv_secret" "vcsa" {
  path = "go/vmware/vcsa"
}

data "vault_kv_secret" "network" {
  path = "go/vmware/network"
}

data "vault_kv_secrets_list" "esx" {
  path = "go/vmware/esx"
}

data "vault_kv_secret" "esxs" {
  for_each = nonsensitive(toset(data.vault_kv_secrets_list.esx.names))
  path     = "go/vmware/esx/${each.value}"
}
