output "vm_info" {
    value = formatlist("%s ansible_host=%s", vsphere_virtual_machine.vm[*].name, vsphere_virtual_machine.vm[*].default_ip_address)
}