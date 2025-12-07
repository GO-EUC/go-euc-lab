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
  for_each = { for vm in flatten([for m in module.domain_controller : try(m.vm, [])]) : vm.name => vm }

  name   = each.value.name
  groups = [ansible_group.dc.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }

  depends_on = [ module.domain_controller ]
}

resource "ansible_group" "mgmt" {
  name = "mgmt"
}

resource "ansible_host" "mgmt" {
  for_each = { for vm in flatten([for m in module.management_server : try(m.vm, [])]) : vm.name => vm }

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
  for_each = { for vm in flatten([for m in module.sql_server : try(m.vm, [])]) : vm.name => vm }

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
  for_each = { for vm in flatten([for m in module.bots : try(m.vm, [])]) : vm.name => vm }

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
  for_each = { for idx, m in module.citrix_storefront : idx => m.vm }

  name   = each.value.name
  groups = [ansible_group.citrix_sf.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }

  depends_on = [ module.citrix_storefront ]
}

resource "ansible_group" "citrix_ddc" {
  name = "citrix_ddc"
}

resource "ansible_host" "citrix_ddc" {
  for_each = { for idx, m in module.citrix_delivery_controller : idx => m.vm }

  name   = each.value.name
  groups = [ansible_group.citrix_ddc.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }

  depends_on = [ module.citrix_delivery_controller ]
}

resource "ansible_group" "citrix_lic" {
  name = "citrix_lic"
}

resource "ansible_host" "citrix_lic" {
  for_each = { for idx, m in module.citrix_license_server : idx => m.vm }

  name   = each.value.name
  groups = [ansible_group.citrix_lic.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }

    depends_on = [ module.citrix_license_server ]
}


resource "ansible_group" "parallels_ras" {
  name = "parallels_ras"
}

resource "ansible_host" "ras" {
  for_each = { for idx, m in module.parallels_ras : idx => m.vm }

  name   = each.value.name
  groups = [ansible_group.parallels_ras.name]

  variables = {
    ansible_host = each.value.default_ip_address
  }

    depends_on = [ module.parallels_ras ]
}
