output "vm" {
    value = tolist(vsphere_virtual_machine.vm[*])
}
