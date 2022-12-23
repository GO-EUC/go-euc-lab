module "vcenter_server_appliance" {
  count  = var.vsphere_deploy == true ? 1 : 0
  source = "./modules/vmware.vcsa"

  esx_host      = cidrhost(var.vsphere_nic_cidr, var.esx_hosts[0])
  esx_username  = var.esx_user
  esx_password  = var.esx_password
  esx_network   = var.esx_nic
  esx_datastore = var.esx_datastore

  vcsa_installation = var.vsphere_source
  vcsa_template     = "modules/vmware.vcsa/templates/vcsa_v${split(".", var.vsphere_version)[0]}.json"
  vcsa_name         = var.vsphere_name
  vcsa_password     = var.vsphere_password
  vcsa_ip           = cidrhost(var.vsphere_nic_cidr, var.vsphere_ip)
  vcsa_gateway      = cidrhost(var.vsphere_nic_cidr, var.vsphere_gateway)
  vcsa_dns          = cidrhost(var.vsphere_nic_cidr, var.vsphere_dns)
  vcsa_prefix       = split("/", var.vsphere_nic_cidr)[1]
  vcsa_ntp          = var.vsphere_ntp
}