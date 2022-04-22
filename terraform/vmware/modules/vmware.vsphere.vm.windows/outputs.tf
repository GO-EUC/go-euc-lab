output "vm_name" {
  value = vsphere_virtual_machine.vm_static[*].name
}

output "vm_ip" {
  value = vsphere_virtual_machine.vm_static[*].default_ip_address
}