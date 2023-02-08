resource "vault_kv_secret" "secret" {
    path = "go/vmware/vcsa"
    data_json = jsonencode({
        password = random_password.password.result
    })
}
