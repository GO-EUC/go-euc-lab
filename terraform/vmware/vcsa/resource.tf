resource "local_file" "vcsa_json" {
  content = templatefile (
    var.vcsa_template, 
    { 
        esx_host = var.esx_host,
        esx_username = var.esx_username,
        esx_password = var.esx_password,
        network = var.esx_network,
        datastore = var.esx_datastore,
        vcsa_name = var.vcsa_name,
        vcsa_ip = var.vcsa_ip,
        vcsa_prefix = var.vcsa_prefix,
        vcsa_gateway = var.vcsa_gateway,
        vcsa_dns = var.vcsa_dns,
        vcsa_password = random_password.password.result,
        vcsa_ntp = var.vcsa_ntp,
        vcsa_system_name = var.vcsa_system_name
    })
  filename = var.config_file_path
}

resource "null_resource" "vcsa_deploy" {
  provisioner "local-exec" {
    command = "${var.vcsa_installation} install --accept-eula --acknowledge-ceip --no-esx-ssl-verify ${var.config_file_path}"
  }
}
