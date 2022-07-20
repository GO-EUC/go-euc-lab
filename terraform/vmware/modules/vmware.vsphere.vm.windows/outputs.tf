output "vm_info" {
    value = formatlist("%s ansible_host=%s", vsphere_virtual_machine.vm_static[*].name, vsphere_virtual_machine.vm_static[*].default_ip_address)
}