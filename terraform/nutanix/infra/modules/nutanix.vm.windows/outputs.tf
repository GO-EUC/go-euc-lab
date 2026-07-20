output "vm_info" {
  value = formatlist("%s ansible_host=%s", null_resource.vm[*].triggers.name, null_resource.vm[*].triggers.ip_address)
}
