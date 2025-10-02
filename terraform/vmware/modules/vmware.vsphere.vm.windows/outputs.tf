output "vm_name" {
    value = vsphere_virtual_machine.vm.name
}

output "vm_ip" {
  value = vsphere_virtual_machine.vm.default_ip_address
}

output "vm_info" {
    value = format("%s ansible_host=%s", vsphere_virtual_machine.vm.name, vsphere_virtual_machine.vm.default_ip_address)
}