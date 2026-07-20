data "vault_kv_secret" "domain" {
  path = "go/domain"
}

data "vault_kv_secret" "build" {
  path = "go/build"
}

data "vault_kv_secret" "prism_central" {
  path = "go/nutanix/prism_central"
}

data "vault_kv_secret" "cluster" {
  path = "go/nutanix/cluster"
}

data "vault_kv_secret" "storage" {
  path = "go/nutanix/storage"
}

data "vault_kv_secret" "network" {
  path = "go/nutanix/network"
}

resource "random_password" "domain" {
  length  = 20
  special = true
}

resource "vault_kv_secret" "domain" {
  path = data.vault_kv_secret.domain.path
  data_json = jsonencode(merge(jsondecode(data.vault_kv_secret.domain.data_json), {
    password = random_password.domain.result
    user     = "Administrator"
  }))
}
