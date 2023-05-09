data "vault_kv_secret" "vcsa" {
    path = "go/vmware/vcsa"
}

resource "vault_kv_secret" "secret" {
    path = data.vault_kv_secret.vcsa.path
    data_json = jsonencode(merge( jsondecode(data.vault_kv_secret.vcsa.data_json), { password = random_password.password.result, user = "administrator@vsphere.local" }))
}
