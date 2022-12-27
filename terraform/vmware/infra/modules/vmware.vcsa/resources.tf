resource "vsphere_datacenter" "datacenter" {
    name = var.vsphere_datacenter
}

resource "vsphere_compute_cluster" "cluster" {
    name            = var.vsphere_cluster
    datacenter_id   = vsphere_datacenter.datacenter.moid
    host_managed    = true
}

data "vsphere_host_thumbprint" "thumbprints" {
  for_each = var.vsphere_hosts 
  address = cidrhost(var.vsphere_nic_cidr, each.value)
  insecure = true
}

resource "vsphere_host" "esx" {
  for_each = data.vsphere_host_thumbprint.thumbprints

  hostname        = cidrhost(var.vsphere_nic_cidr, each.key) #"10.2.0.11"
  username        = var.esx_username
  password        = var.esx_password
  cluster         = vsphere_compute_cluster.cluster.id
  thumbprint      = each.value.id
}

resource "vsphere_file" "iso_server" {
  datacenter         = vsphere_datacenter.datacenter.name
  datastore          = "datastore1"
  source_file        = "C:\\Software\\Microsoft\\WindowsServer_2022.iso"
  destination_file   = "/ISO/WindowsServer_2022.iso"
  create_directories = true
}

resource "vsphere_file" "iso_client" {
  datacenter         = vsphere_datacenter.datacenter.name
  datastore          = "datastore2"
  source_file        = "C:\\Software\\Microsoft\\Windows_11_22h2.iso"
  destination_file   = "/ISO/Windows_11_22h2.iso"
  create_directories = true
}

resource "vsphere_file" "iso_client_w10" {
  datacenter         = vsphere_datacenter.datacenter.name
  datastore          = "datastore2"
  source_file        = "C:\\Software\\Microsoft\\Windows_10_22h2.iso"
  destination_file   = "/ISO/Windows_10_22h2.iso"
  create_directories = true
}