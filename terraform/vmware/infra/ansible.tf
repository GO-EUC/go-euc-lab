resource "ansible_group" "all" {
  name = "all"
  variables = {
    vault_addr       = var.vault_address
    vault_token      = var.vault_token
    vsphere_password = jsondecode(data.vault_kv_secret.vcsa.data_json).password
    delivery         = "citrix"
  }
}


resource "ansible_group" "dc" {
  name = "dc"
}

resource "ansible_host" "dc" {
  for_each = { for vm in module.domain_controller.vm : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.dc.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "mgmt" {
  name = "mgmt"
}

resource "ansible_host" "mgmt" {
  for_each = { for vm in module.management_server.vm : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.mgmt.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "sql" {
  name = "sql"
}

resource "ansible_host" "sql" {
  for_each = { for vm in module.sql_server.vm : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.sql.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "bots" {
  name = "bots"
}

resource "ansible_host" "bots" {
  for_each = { for vm in module.bots.vm : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.bots.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "citrix_sf" {
  name = "citrix_sf"
}

resource "ansible_host" "citrix_sf" {
  for_each = { for vm in try(module.citrix_storefront[0].vm, []) : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.citrix_sf.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "citrix_ddc" {
  name = "citrix_ddc"
}

resource "ansible_host" "citrix_ddc" {
  for_each = { for vm in try(module.citrix_delivery_controller[0].vm, []) : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.citrix_ddc.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}

resource "ansible_group" "citrix_lic" {
  name = "citrix_lic"
}

resource "ansible_host" "citrix_lic" {
  for_each = { for vm in try(module.citrix_license_server[0].vm, []) : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.citrix_lic.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }
}
